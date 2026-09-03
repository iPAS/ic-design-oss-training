#!/bin/bash

ROOT="$(realpath "$(pwd)/../tools/root")"

XSCHEM_SHAREDIR="$ROOT/usr/share/xschem" \
    "$ROOT/usr/bin/xschem"
