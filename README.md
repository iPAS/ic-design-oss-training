# Analog IC Design with Open-Source Tools

Workspace for the TMEC/NSTDA course *Analog IC Design using Open-Source Tools*
(instructor: Wittawat Yamwong -- https://github.com/wityam/aicoss).

The course ships its toolchain as `wityam-aicoss/eda.tar.xz`, which
`bootstrap.sh` untars into `/usr/local` of a **WSL Ubuntu 26.04** image.  That
is not usable on this machine -- it runs Ubuntu 24.04 natively, and the tarball
carries `lib/python3.14/dist-packages` and installs system-wide.  So the tools
are **built from source into `tools/root`**, and nothing is installed into the
OS.  The apt-provided ngspice/magic/netgen/klayout are left alone; `PATH` order
decides which wins.

| tool | version here | what it does |
|---|---|---|
| xschem  | 3.4.8RC  | schematic capture |
| ngspice | 47+      | circuit simulation |
| magic   | 8.3.683  | layout, DRC, extraction |
| netgen  | 1.5.323  | LVS |
| klayout | 0.30.12  | layout viewer/editor |
| gaw     | git      | analog waveform viewer |

PDK: **GlobalFoundries GF180MCU** (`gf180mcuC`), the one the course uses.
**SkyWater SKY130** (`sky130A`) is installed alongside it as an alternative --
see [Switching PDK](#switching-pdk). Both come from `ciel`.

---

## Install

Four steps, from a clean checkout.  Only the first touches the system.

### 1. Build dependencies (the only `sudo` in this document)

```bash
sudo apt install build-essential git flex bison m4 autoconf automake libtool \
                 libx11-dev libxpm-dev libxrender-dev libxaw7-dev libcairo2-dev \
                 tcl-dev tk-dev libreadline-dev libncurses-dev \
                 libgtk-3-dev libglu1-mesa-dev
```

`tools/build.sh` refuses to start if any of these is missing, and names the
ones to install.

### 2. Python environment

```bash
./tools/venv_install.sh
```

Creates the virtualenv at `$VENV` and installs `tools/requirements.txt`
(`ciel`).  Nothing lands outside that directory -- no `--user`, no system pip.

### 3. The PDK

Skip this if you already have one; point `PDK_ROOT` at it in `tools/env.sh`
instead.  Otherwise, several GB of download:

```bash
source tools/env.sh
tools/ciel_install_pdks.sh
```

It installs both families into `$PDK_ROOT`: `gf180mcuA`..`gf180mcuD` and
`sky130A`/`sky130B`. `tools/env.sh` picks one of them with `PDK`.

### 4. The toolchain

```bash
./tools/build.sh                  # all six, roughly 15-30 min
./tools/build.sh magic netgen     # just those
./tools/build.sh --clean xschem   # wipe its build tree first
./tools/build.sh --list           # what can be built
```

Sources are cloned into `tools/src/`, installs land in `tools/root/usr/`; both
are gitignored.  KLayout is the exception -- it is not compiled.  The official
Ubuntu-24 `.deb` is unpacked with `dpkg-deb -x`, which needs no root and saves a
multi-hour Qt build.

### 5. ngspice's init file

Lives outside the project, in whichever directory you simulate from
(xschem uses `~/.xschem/simulations`):

```bash
mkdir -p ~/.xschem/simulations
cp xschem-sim.spiceinit ~/.xschem/simulations/.spiceinit
```

Without it ngspice rejects the PDK's models -- `ngbehavior=hsa` is what makes
it read HSPICE-style model files.

---

## Verify

```bash
./check.sh
```

Every tool must resolve **under `tools/root`**.  A path in `/usr/bin` means that
tool did not build and the apt copy answered instead:

```
=== which
ok   xschem   .../tools/root/usr/bin/xschem
ok   ngspice  .../tools/root/usr/bin/ngspice
...
=== unresolved shared libraries
ok   every ELF file under usr/bin and usr/lib resolves
=== pdk
ok   present
```

---

## Daily use

```bash
bin/xschem.sh                # or bin/magic.sh -- from any directory
```

The launchers source `tools/env.sh`, change into `designs/`, and hand the tool its
rc file from `bin/` (`xschem --rcfile=bin/xschemrc`, `magic -rcfile bin/magicrc`).
Those rc files are what point both tools at the PDK.

`designs/` is your work space -- schematics, symbols, layouts. Everything in it
is git-ignored (only `designs/.gitkeep` is tracked, so the directory exists in a
fresh clone). Scripts and rc files belong in `bin/`. Starting `xschem` or `magic` directly, without the launcher, skips
the rc file and the PDK is not loaded.

Typical flow: draw in **xschem** -> `Simulation > Netlist` -> `Simulate` runs
**ngspice** -> view curves in xschem's built-in graph or in **gaw** -> layout in
**magic** with the PDK's DRC -> extract and compare against the schematic netlist
with **netgen** -> inspect or hand off GDS in **klayout**.

### Switching PDK

The course uses `gf180mcuC`; `sky130A` is the alternative. The choice is one
line in `tools/env.sh`:

```bash
export PDK="gf180mcuC"     # course default
#export PDK="sky130A"      # alternative: SkyWater SKY130
```

Re-run the launcher (or re-`source tools/env.sh`) after changing it. Nothing
else needs editing: `bin/xschemrc` and `bin/magicrc` read `$env(PDK)`, so
xschem, ngspice, magic and netgen all follow.

A schematic belongs to the PDK it was drawn with -- its device symbols come from
that PDK's library. A gf180 schematic opened under `sky130A` shows every device
as `IS MISSING`, and the other way round.

---

## How it is wired

`tools/env.sh` is the single source of truth.  Each of these is defined there
exactly once and read back by everything else:

| variable | meaning | read by |
|---|---|---|
| `EDA_ROOT`  | where the toolchain installs | `tools/build.sh` (as `--prefix`), `check.sh` |
| `VENV`      | where the python env lives   | `tools/venv_install.sh` |
| `PDK_ROOT`  | PDK install directory        | `bin/xschemrc`, `bin/magicrc`, `check.sh` |
| `PDK`       | which PDK (`gf180mcuC`, or `sky130A`) | same |
| `CAD_ROOT`  | magic's Tcl startup files    | magic's launcher |

`build.sh` and `venv_install.sh` read `env.sh` in a **subshell**, so its other
effects -- prepending `PATH`, activating the venv -- cannot leak into a build.

Three things that are easy to get wrong:

- **The rc files are Tcl, not shell.** `bin/xschemrc` and `bin/magicrc`
  must use `$env(PDK_ROOT)`, never `$PDK_ROOT`. The bare form is not an error
  you will see: the `source` silently fails, and every device netlists as
  `IS MISSING`.
- **The tree is not relocatable.** Absolute prefixes are compiled into the
  binaries (xschem's sharedir, magic's `CAD_ROOT`, ngspice's `spinit` and
  code-model directory). Move the project and you must rebuild.
- **The PDK is on a separate volume.** If `/media/ipas/archive` is not mounted,
  `env.sh` warns, and the tools start with no libraries rather than failing.

---

## Troubleshooting

| symptom | cause |
|---|---|
| every device netlists as `IS MISSING` | xschem started without `bin/xschem.sh`, or `xschemrc` used `$PDK_ROOT` instead of `$env(PDK_ROOT)`, or `PDK_ROOT` is unset -- the PDK's xschemrc then quietly guesses `/usr/share/pdk` |
| magic reports technology `minimum` | magic was started directly instead of through `bin/magic.sh`, so `bin/magicrc` was never read |
| `check.sh` shows a tool in `/usr/bin` | that tool did not build; the apt copy answered |
| ngspice: `Could not find include file <name>.save` | xschem writes that file only when simulating from the GUI, not when netlisting in batch |
| ngspice: `Undefined parameter [l]` / model errors | `.spiceinit` missing from the simulation directory (step 5) |
| klayout: `libklayout_*.so.0: cannot open shared object file` | the deb's binaries hardcode `RUNPATH=/usr/lib/klayout`; `build.sh` installs wrappers for this -- re-run `./tools/build.sh klayout` |

---

## Reference

Course

- https://tmec.nectec.or.th/lmsX/course/section.php?id=6
- https://github.com/wityam/aicoss

xschem

- https://xschem.sourceforge.io/stefan/xschem_man/install_xschem.html
- https://xschem.sourceforge.io/stefan/xschem_man/tutorial_xschem_sky130.html

Further reading

- https://github.com/mattvenn/awesome-opensource-asic-resources
- https://github.com/iic-jku/iic-osic-tools
- https://github.com/bmurmann/Book-on-MOS-stages
