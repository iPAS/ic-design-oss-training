# Tasks

## Proposed

## Doing

## Done
- [x] Verified the flow end to end: xschem netlists a sky130 testbench with 0 missing symbols, ngspice-47+ simulates it to a raw file, magic loads sky130A from `designs/`, netgen LVS matches with the PDK setup, klayout reads a PDK GDS — 2026-09-03
- [x] Fixed `designs/xschemrc`: it is Tcl, so `$PDK_ROOT` never expanded — every symbol came out "IS MISSING". Now `$env(PDK_ROOT)`. Added `designs/.magicrc` + `designs/magic.sh` — 2026-09-03
- [x] KLayout: deb binaries carry `RUNPATH=/usr/lib/klayout`; `build.sh` now moves them beside their libs and installs LD_LIBRARY_PATH wrappers — 2026-09-03
- [x] Built the whole toolchain into `tools/root`: xschem 3.4.8RC, ngspice 47+, magic 8.3.683, netgen 1.5.323, gaw, klayout 0.30.12 — 2026-09-03
- [x] Fixed the gaw source URL in `build.sh` (`xschem_gaw` 404 → `xschem-gaw`) — 2026-09-03
- [x] Rewrote `check.sh` (sources env.sh, flags apt vs local paths, ldd + PDK check); `designs/xschem.sh` reduced to env.sh + exec; `designs/xschemrc` back to `$PDK_ROOT/$PDK`; README "Local toolchain" section — 2026-09-03
- [x] Removed the stale `tools/root/usr` (old `--prefix=/usr` + DESTDIR build; its xschem binary had `/usr/share/xschem` compiled in) — 2026-09-03, moved to trash
- [x] Moved `tools/xschem_git` → `tools/src/xschem`, where `build.sh` expects its sources — 2026-09-03
- [x] `git init` on the project; baseline commit on `master`, work continues on branch `build/local-toolchain` — 2026-09-03
- [x] Installed `libreadline-dev` (user) — 2026-09-03
- [x] Rewrote `tools/build.sh`: absolute `--prefix` into `tools/root/usr` instead of `--prefix=/usr` + `DESTDIR`, per-tool targets, no more blanket `trash root` — 2026-09-03
- [x] Added `tools/env.sh` (PATH, CAD_ROOT, PDK_ROOT=sky130A on /media/ipas/archive, venv) — 2026-09-03
- [-] Use the instructor's prebuilt `wityam-aicoss/eda.tar.xz` — 2026-09-03 (built for Ubuntu 26.04/WSL; this machine is 24.04, and it installs into /usr/local)
