#!/bin/bash
#
# Source this before doing any course work:
#
#     source tools/env.sh
#
# It puts the locally built toolchain in tools/root ahead of the apt-installed
# copies and points the tools at the sky130A PDK.  Nothing here is global.

_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJ_DIR="$(dirname "${_TOOLS_DIR}")"
_ROOT="${_TOOLS_DIR}/root"

export PATH="${_ROOT}/usr/bin:${PATH}"
export MANPATH="${_ROOT}/usr/share/man:${MANPATH}"

# magic's launcher script resolves its Tcl startup files under ${CAD_ROOT}/magic/tcl.
# Set it explicitly so it can never fall back to the hardcoded /usr/local default.
export CAD_ROOT="${_ROOT}/usr/lib"

export PDK_ROOT="/media/ipas/archive/Development_FPGA/ciel"
export PDK="sky130A"

# ciel and the other python helpers live in the project venv
if [[ -f "${_PROJ_DIR}/venv/bin/activate" ]]; then
    source "${_PROJ_DIR}/venv/bin/activate"
fi

if [[ ! -d "${PDK_ROOT}/${PDK}" ]]; then
    echo "WARNING: PDK not found at ${PDK_ROOT}/${PDK}" >&2
    echo "         Is /media/ipas/archive mounted?  xschem and magic will start" >&2
    echo "         but show no sky130 libraries." >&2
fi

unset _TOOLS_DIR _PROJ_DIR _ROOT
