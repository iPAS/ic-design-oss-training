#!/bin/bash
#
# Create the project's python environment at the VENV path defined in env.sh.
#
#     ./venv_install.sh            create it if missing, then install/update
#     ./venv_install.sh --force    delete and recreate it first
#     ./venv_install.sh --list     show where it would go and what is in it
#
# Packages come from tools/requirements.txt.  Nothing is installed outside
# ${VENV}: no --user, no system pip, no change to the OS python.

set -euo pipefail

TOOLS="$(cd "$(dirname "$0")" && pwd)"
REQ="${TOOLS}/requirements.txt"
PDK_COMMIT="026824c7969ce6f4fc9678e6ca04b0a06a596c4b"

say() { printf '\n\033[1;34m### %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# env.sh owns the location.  Read it in a subshell so its other effects --
# prepending PATH, activating whatever venv already exists -- stay out of here.
VENV="$(set +eu; . "${TOOLS}/env.sh" >/dev/null 2>&1; printf '%s' "${VENV:-}")"
[[ -n "${VENV}" ]] || die "${TOOLS}/env.sh did not set VENV"

FORCE=0
for arg in "$@"; do
    case "${arg}" in
        --force) FORCE=1 ;;
        --list)
            echo "VENV         ${VENV}"
            echo "requirements ${REQ}"
            if [[ -x "${VENV}/bin/pip" ]]; then
                echo "installed:"
                "${VENV}/bin/pip" list --not-required
            else
                echo "installed:   (nothing -- no environment there yet)"
            fi
            exit 0 ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) die "unknown option ${arg}" ;;
    esac
done

[[ -f "${REQ}" ]] || die "no requirements file at ${REQ}"

if (( FORCE )) && [[ -d "${VENV}" ]]; then
    say "removing ${VENV}"
    # trash where possible, but it refuses across filesystems -- and the
    # environment is reproducible from requirements.txt, so fall back to rm
    # rather than leaving --force half done.
    if ! { command -v trash >/dev/null && trash "${VENV}" 2>/dev/null; }; then
        echo "(trash unavailable or refused; deleting outright)" >&2
        rm -rf "${VENV}"
    fi
fi

if [[ ! -x "${VENV}/bin/python" ]]; then
    [[ -e "${VENV}" ]] && die "${VENV} exists but holds no python -- use --force"
    say "creating ${VENV}"
    # virtualenv if it is around (it built the original), the stdlib module otherwise
    if command -v virtualenv >/dev/null; then
        virtualenv -p python3 "${VENV}"
    else
        python3 -m venv "${VENV}"
    fi
fi

say "installing ${REQ} into ${VENV}"
"${VENV}/bin/pip" install --upgrade pip
"${VENV}/bin/pip" install -r "${REQ}"

say "verifying"
"${VENV}/bin/python" --version
"${VENV}/bin/ciel" --version || die "ciel installed but does not run"

cat <<EOF

Done.  'source tools/env.sh' now activates ${VENV}.

The PDK itself is not installed by this script.  If you need it:

    source tools/env.sh
    ciel enable ${PDK_COMMIT}

which downloads into \$PDK_ROOT -- several GB, and it is already present
if check.sh reports the PDK as ok.
EOF
