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

ROOT="$(pwd)/tools/root"

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
xschem --version   2>&1 | head -2
ngspice --version  2>&1 | head -2
magic --version    2>&1 | head -1
netgen -batch quit 2>&1 | head -2
klayout -v         2>&1 | head -1

echo
echo "=== unresolved shared libraries"
for b in "${ROOT}"/usr/bin/*; do
    [[ -x "${b}" && ! -d "${b}" ]] || continue
    miss="$(ldd "${b}" 2>/dev/null | grep 'not found' || true)"
    [[ -n "${miss}" ]] && printf '%s\n%s\n' "${b}" "${miss}"
done
echo "(nothing above = all libraries resolve)"

echo
echo "=== pdk"
printf 'PDK_ROOT %s\n' "${PDK_ROOT}"
printf 'PDK      %s\n' "${PDK}"
[[ -d "${PDK_ROOT}/${PDK}" ]] && echo "ok   present" || echo "MISS not mounted?"
