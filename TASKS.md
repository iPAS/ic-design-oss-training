# Tasks

## Proposed

## Doing
- [~] Build the EDA toolchain into `tools/root` — started 2026-09-03. Nothing built yet. Next: `./tools/build.sh --clean xschem` then `./tools/build.sh` for the rest.
- [~] Still to write: updated `check.sh`, `designs/xschem.sh` + `designs/xschemrc`, README "Local toolchain" section — started 2026-09-03

## Done
- [x] Removed the stale `tools/root/usr` (old `--prefix=/usr` + DESTDIR build; its xschem binary had `/usr/share/xschem` compiled in) — 2026-09-03, moved to trash
- [x] Moved `tools/xschem_git` → `tools/src/xschem`, where `build.sh` expects its sources — 2026-09-03
- [x] `git init` on the project; baseline commit on `master`, work continues on branch `build/local-toolchain` — 2026-09-03
- [x] Installed `libreadline-dev` (user) — 2026-09-03
- [x] Rewrote `tools/build.sh`: absolute `--prefix` into `tools/root/usr` instead of `--prefix=/usr` + `DESTDIR`, per-tool targets, no more blanket `trash root` — 2026-09-03
- [x] Added `tools/env.sh` (PATH, CAD_ROOT, PDK_ROOT=sky130A on /media/ipas/archive, venv) — 2026-09-03
- [-] Use the instructor's prebuilt `wityam-aicoss/eda.tar.xz` — 2026-09-03 (built for Ubuntu 26.04/WSL; this machine is 24.04, and it installs into /usr/local)
