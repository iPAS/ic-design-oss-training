#!/bin/bash
#
# Prove the locally built toolchain is the one in use.
#
#     ./check.sh
#
# Every path printed must be under tools/root/usr/bin.  A path in /usr/bin
# means the apt copy won, i.e. the tool did not build or env.sh was not sourced.

cd "$(dirname "$0")"
source tools/env.sh

ROOT="${EDA_ROOT}"

echo "=== which"
for t in xschem ngspice magic netgen klayout gaw; do
    p="$(command -v "$t" || true)"
    case "${p}" in
        "${ROOT}"/*) mark="ok  " ;;
        "")          mark="MISS" ;;
        *)           mark="APT!" ;;
    esac
    printf '%s %-8s %s\n' "${mark}" "${t}" "${p:-not found}"
done

echo
echo "=== versions"
exec 3<&0 </dev/null          # no probe may sit waiting on stdin
xschem --version   2>&1 | head -2
ngspice --version  2>&1 | head -2
magic --version    2>&1 | head -1
netgen -batch quit 2>&1 | head -2
klayout -v         2>&1 | head -1
exec 0<&3 3<&-

echo
echo "=== unresolved shared libraries"
# bin/ holds shell wrappers for the klayout binaries (see build_klayout), and
# ldd says nothing useful about a script -- so scan the real ELF files too.
# the klayout binaries find their libraries through the wrapper's
# LD_LIBRARY_PATH, so give ldd the same view or every one reports "not found"
export LD_LIBRARY_PATH="${ROOT}/usr/lib/klayout${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
found=0
while IFS= read -r b; do
    head -c4 "${b}" | grep -q ELF || continue
    miss="$(ldd "${b}" 2>/dev/null | grep 'not found' || true)"
    if [[ -n "${miss}" ]]; then
        printf '%s\n%s\n' "${b}" "${miss}"
        found=1
    fi
done < <(find "${ROOT}/usr/bin" "${ROOT}/usr/lib" -type f -perm -u+x 2>/dev/null)
(( found )) || echo "ok   every ELF file under usr/bin and usr/lib resolves"

echo
echo "=== pdk"
printf 'PDK_ROOT %s\n' "${PDK_ROOT}"
printf 'PDK      %s\n' "${PDK}"
[[ -d "${PDK_ROOT}/${PDK}" ]] && echo "ok   present" || echo "MISS not mounted?"
