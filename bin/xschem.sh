#!/bin/bash
#
# Start xschem in designs/ with the local toolchain and the sky130 libraries.
# xschem only looks for ./xschemrc in the current directory, and designs/ holds
# sources only -- so the rc file lives here in bin/ and is passed explicitly.

BIN="$(cd "$(dirname "$0")" && pwd)"
source "${BIN}/../tools/env.sh"
cd "${BIN}/../designs"
exec xschem --rcfile="${BIN}/xschemrc" "$@"
