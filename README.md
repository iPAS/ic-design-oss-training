
## Installaion

https://xschem.sourceforge.io/stefan/xschem_man/install_xschem.html

https://xschem.sourceforge.io/stefan/xschem_man/tutorial_xschem_sky130.html


## Local toolchain

The course distributes its EDA tools as `wityam-aicoss/eda.tar.xz`, which
`bootstrap.sh` untars into `/usr/local` of a **WSL Ubuntu 26.04** image.  That is
not usable here: this machine is Ubuntu 24.04 (the tarball carries
`lib/python3.14/dist-packages`), and it installs system-wide.  So the tools are
built from source into `tools/root` instead, and nothing is installed globally.

Each tool is configured with an absolute `--prefix=<repo>/tools/root/usr` and
installed **without** `DESTDIR`, so every path compiled into the binaries --
xschem's sharedir, magic's `CAD_ROOT`, ngspice's `spinit` and code-model
directory -- points at its real location.  The consequence: **the tree is not
relocatable.  If you move the project, rebuild.**

### Build

One prerequisite from apt:

```bash
sudo apt install libreadline-dev
```

Then:

```bash
./tools/build.sh                  # everything
./tools/build.sh magic netgen     # just those
./tools/build.sh --clean xschem   # wipe its build tree first
./tools/build.sh --list           # what can be built
```

Sources are cloned into `tools/src/`; installs land in `tools/root/usr/`.  Both
are gitignored.  The install location is defined once, as `EDA_ROOT` in
`tools/env.sh`; `build.sh` and `check.sh` read it back from there, so change it
in that one place (and rebuild -- the prefix is compiled in).  KLayout is not built -- the official Ubuntu-24 `.deb` is
unpacked with `dpkg-deb -x`, which needs no root and saves a multi-hour Qt build.

### Python side

`ciel` and its dependencies live in a virtualenv, never in the system python:

```bash
./tools/venv_install.sh            # create it and install tools/requirements.txt
./tools/venv_install.sh --force    # recreate it from scratch
./tools/venv_install.sh --list     # where it is, and what is in it
```

Its location is `VENV` in `tools/env.sh` -- the one definition, read back by the
install script.  Point it somewhere else and `.gitignore` needs the new path.
The PDK download (`ciel enable <commit>`) is deliberately not automated; the
script prints the command.

### Use

```bash
source tools/env.sh   # PATH, CAD_ROOT, PDK_ROOT, PDK, venv
./check.sh            # every path must be under tools/root/usr/bin
```

The apt-installed ngspice/magic/netgen/klayout stay where they are; the `PATH`
order set by `env.sh` decides which wins.

Inside `designs/` the two rc files point the tools at the PDK.  Both are read as
**Tcl**, so environment variables are `$env(PDK_ROOT)`, not `$PDK_ROOT`:

- `designs/xschemrc` -- sources the PDK's xschemrc (symbol libraries)
- `designs/.magicrc` -- sources the PDK's magicrc (sky130A tech, DRC styles)

`designs/xschem.sh` and `designs/magic.sh` just source `tools/env.sh` and exec
the tool from the right directory.


## Setup

```bash
export PDK_ROOT=<pdk-dir>
export PDK=sky130A
```

```bash
virtualenv -p python3.12 venv
source venv/bin/activate
pip install ciel
ciel enable 026824c7969ce6f4fc9678e6ca04b0a06a596c4b
```

```bash
mkdir -p ~/.xschem/simulations
cat << EOF > ~/.xschem/simulations/.spiceinit
set ngbehavior=hsa
set ng_nomodcheck
EOF
```

```bash
echo "source $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc" \
> <design-dir>/xschemrc
```

## Workflow

- Go inside `<design-dir>` before calling `xschem`

## Note

- https://tmec.nectec.or.th/lmsX/course/section.php?id=6
- https://github.com/wityam/aicoss

https://github.com/mattvenn/awesome-opensource-asic-resources
https://github.com/iic-jku/iic-osic-tools
https://github.com/bmurmann/Book-on-MOS-stages
