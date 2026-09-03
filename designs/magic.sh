#!/bin/bash
#
# Start magic from this directory with the local toolchain and the sky130 tech.
# The tech comes from ./.magicrc, which sources the PDK's own magicrc.

cd "$(dirname "$0")"
source ../tools/env.sh
exec magic "$@"
