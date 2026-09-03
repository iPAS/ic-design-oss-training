# Tasks

## Proposed

## Doing
- [~] Build the EDA toolchain into `tools/root` — started 2026-09-03. Scripts written, nothing built yet. Next: `sudo apt install libreadline-dev`, move `tools/xschem_git` → `tools/src/xschem`, delete the old wrongly-prefixed `tools/root/usr`, then `./tools/build.sh`.
- [~] Still to write: updated `check.sh`, `designs/xschem.sh` + `designs/xschemrc`, README "Local toolchain" section — started 2026-09-03

## Done
- [x] Rewrote `tools/build.sh`: absolute `--prefix` into `tools/root/usr` instead of `--prefix=/usr` + `DESTDIR`, per-tool targets, no more blanket `trash root` — 2026-09-03
- [x] Added `tools/env.sh` (PATH, CAD_ROOT, PDK_ROOT=sky130A on /media/ipas/archive, venv) — 2026-09-03
- [-] Use the instructor's prebuilt `wityam-aicoss/eda.tar.xz` — 2026-09-03 (built for Ubuntu 26.04/WSL; this machine is 24.04, and it installs into /usr/local)
