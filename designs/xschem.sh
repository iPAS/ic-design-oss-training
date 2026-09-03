#!/bin/bash
#
# Start xschem from this directory with the local toolchain.
# The XSCHEM_SHAREDIR override is gone: xschem is now built with its real
# prefix compiled in, so it finds its own share directory.

cd "$(dirname "$0")"
source ../tools/env.sh
exec xschem "$@"
