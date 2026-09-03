#!/bin/bash
#
# Build the course EDA toolchain into tools/root -- no global installation.
#
#   ./build.sh                  build everything
#   ./build.sh magic netgen     build only those
#   ./build.sh --clean xschem   wipe that tool's build tree first, then build
#   ./build.sh --list           show what can be built
#
# Every tool is configured with an absolute --prefix pointing into tools/root/usr
# and installed WITHOUT DESTDIR, so the paths compiled into the binaries (xschem's
# sharedir, magic's CAD_ROOT, ngspice's spinit and code-model directory) all point
# at their real location.  The tree is therefore not relocatable: if you move the
# project, rebuild.
#
# Run `source tools/env.sh` to use what this produces.

set -euo pipefail

TOOLS="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${TOOLS}/root/usr"
SRC="${TOOLS}/src"
JOBS="$(nproc)"

KLAYOUT_VER="0.30.12-1"
KLAYOUT_URL="https://www.klayout.org/downloads/Ubuntu-24/klayout_${KLAYOUT_VER}_amd64.deb"

ALL_TOOLS=(xschem ngspice magic netgen gaw klayout)
CLEAN=0


### helpers ##################################################################

say() { printf '\n\033[1;34m### %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

check_deps() {
    local missing=()
    local pkgs=(build-essential git flex bison m4 autoconf automake libtool
                libx11-dev libxpm-dev libxrender-dev libxaw7-dev libcairo2-dev
                tcl-dev tk-dev libreadline-dev libncurses-dev
                libgtk-3-dev libglu1-mesa-dev)
    for p in "${pkgs[@]}"; do
        dpkg -s "$p" &>/dev/null || missing+=("$p")
    done
    if (( ${#missing[@]} )); then
        die "missing build dependencies. Run:
    sudo apt install ${missing[*]}"
    fi
}

# fetch_src <name> <git-url>  ->  leaves you in ${SRC}/<name>
fetch_src() {
    local name="$1" url="$2"
    mkdir -p "${SRC}"
    if [[ ! -d "${SRC}/${name}" ]]; then
        say "cloning ${name}"
        git clone --depth 1 "${url}" "${SRC}/${name}"
    fi
    cd "${SRC}/${name}"
}

# verify <label> <command...>
verify() {
    local label="$1"; shift
    say "verifying ${label}"
    "$@" || die "${label} was installed but does not run"
}


### tools ####################################################################

build_xschem() {
    fetch_src xschem https://github.com/StefanSchippers/xschem.git
    if (( CLEAN )); then make clean || true; fi
    ./configure --prefix="${PREFIX}"
    make -j"${JOBS}"
    make install
    verify xschem "${PREFIX}/bin/xschem" --version
}

build_ngspice() {
    fetch_src ngspice https://git.code.sf.net/p/ngspice/ngspice
    if (( CLEAN )); then rm -rf release; fi
    if [[ -x ./autogen.sh ]]; then ./autogen.sh; fi
    mkdir -p release && cd release
    ../configure --prefix="${PREFIX}" \
        --with-x \
        --with-readline=yes \
        --enable-xspice \
        --enable-cider \
        --enable-openmp \
        --enable-osdi \
        --disable-debug
    make -j"${JOBS}"
    make install
    verify ngspice "${PREFIX}/bin/ngspice" --version
}

build_magic() {
    fetch_src magic https://github.com/RTimothyEdwards/magic.git
    if (( CLEAN )); then make clean || true; fi
    ./configure --prefix="${PREFIX}"
    make -j"${JOBS}"
    make install
    verify magic "${PREFIX}/bin/magic" --version
}

build_netgen() {
    fetch_src netgen https://github.com/RTimothyEdwards/netgen.git
    if (( CLEAN )); then make clean || true; fi
    ./configure --prefix="${PREFIX}"
    make -j"${JOBS}"
    make install
    verify netgen "${PREFIX}/bin/netgen" -batch quit
}

build_gaw() {
    fetch_src gaw https://github.com/StefanSchippers/xschem-gaw.git
    if (( CLEAN )); then make clean || true; fi
    if [[ -x ./autogen.sh ]]; then ./autogen.sh; fi
    ./configure --prefix="${PREFIX}"
    make -j"${JOBS}"
    make install
    verify gaw test -x "${PREFIX}/bin/gaw"
}

# KLayout is a multi-hour Qt/C++ build; the upstream Ubuntu-24 .deb unpacks
# cleanly into our tree with dpkg-deb -x and needs no root.
build_klayout() {
    local deb="${SRC}/klayout_${KLAYOUT_VER}_amd64.deb"
    mkdir -p "${SRC}"
    if [[ ! -f "${deb}" ]]; then
        say "downloading klayout ${KLAYOUT_VER}"
        curl -fL -o "${deb}.part" "${KLAYOUT_URL}"
        mv "${deb}.part" "${deb}"
    fi
    say "unpacking klayout into ${TOOLS}/root"
    dpkg-deb -x "${deb}" "${TOOLS}/root"

    # Every binary in the deb carries RUNPATH=/usr/lib/klayout, an absolute path
    # that does not exist outside a system-wide install.  patchelf would fix the
    # ELF header but is not installed and would be an apt change; instead each
    # binary is moved next to its libraries and replaced by a wrapper that sets
    # LD_LIBRARY_PATH.  dpkg-deb -x restores the real binaries on every run, so
    # this stays idempotent.
    say "wrapping klayout binaries (deb RUNPATH is /usr/lib/klayout)"
    local libdir="${PREFIX}/lib/klayout"
    local b name
    # only the names the deb itself ships -- the other tools in bin/ are ours
    for name in $(dpkg-deb -c "${deb}" | awk '$6 ~ /^\.\/usr\/bin\/./ {sub(".*/", "", $6); print $6}'); do
        b="${PREFIX}/bin/${name}"
        [[ -f "${b}" ]] || continue
        mv "${b}" "${libdir}/${name}.bin"
        cat > "${b}" <<WRAP
#!/bin/sh
# generated by tools/build.sh -- see build_klayout()
_d="\$(cd "\$(dirname "\$0")/../lib/klayout" && pwd)"
LD_LIBRARY_PATH="\${_d}\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
export LD_LIBRARY_PATH
exec "\${_d}/${name}.bin" "\$@"
WRAP
        chmod +x "${b}"
    done
    verify klayout "${PREFIX}/bin/klayout" -v
}


### dispatch #################################################################

targets=()
for arg in "$@"; do
    case "${arg}" in
        --clean) CLEAN=1 ;;
        --list)  printf '%s\n' "${ALL_TOOLS[@]}"; exit 0 ;;
        -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
        -*)      die "unknown option ${arg}" ;;
        *)       targets+=("${arg}") ;;
    esac
done
(( ${#targets[@]} )) || targets=("${ALL_TOOLS[@]}")

for t in "${targets[@]}"; do
    declare -F "build_${t}" >/dev/null || die "unknown tool '${t}' (see --list)"
done

check_deps
mkdir -p "${PREFIX}"

for t in "${targets[@]}"; do
    say "building ${t}  ->  ${PREFIX}"
    ( "build_${t}" )
done

say "done. Now: source ${TOOLS}/env.sh"
