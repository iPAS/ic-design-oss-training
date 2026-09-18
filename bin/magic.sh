#!/bin/bash
#
# Start magic in designs/ with the local toolchain and the sky130 tech.
# magic only looks for ./.magicrc in the current directory, and designs/ holds
# sources only -- so the rc file lives here in bin/ and is passed explicitly.

BIN="$(cd "$(dirname "$0")" && pwd)"
source "${BIN}/../tools/env.sh"
cd "${BIN}/../designs"
exec magic -rcfile "${BIN}/magicrc" "$@"
