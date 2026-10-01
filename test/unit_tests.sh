#!/bin/bash
# Fast unit tests for pure installer logic; complements the Docker-based distro tests.

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'
PASS_SYMBOL="✓"
FAIL_SYMBOL="✗"

if [[ ! -t 1 ]]; then
    RED='' GREEN='' BLUE='' BOLD='' NC='' PASS_SYMBOL='' FAIL_SYMBOL=''
fi

PARENT_DIR=$(git rev-parse --show-toplevel)
INSTALLER="${PARENT_DIR}/psychopy_linux_installer"

ERRORS=0
CHECKS=0

print_header() {
    echo -e "\n${BLUE}${BOLD}$1${NC}"
    echo -e "${BLUE}$(printf '%.0s-' $(seq 1 ${#1}))${NC}\n"
}

# assert_eq DESCRIPTION EXPECTED ACTUAL
assert_eq() {
    local description="$1" expected="$2" actual="$3"
    ((CHECKS++))
    if [ "${expected}" = "${actual}" ]; then
        echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: ${description}"
    else
        echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: ${description} (expected '${expected}', got '${actual}')"
        ((ERRORS++))
    fi
}

# assert_true DESCRIPTION -- COMMAND...
# assert_false DESCRIPTION -- COMMAND...
assert_true() {
    local description="$1"
    shift 2 # drop the literal '--'
    ((CHECKS++))
    if "$@"; then
        echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: ${description}"
    else
        echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: ${description} (expected success, got failure)"
        ((ERRORS++))
    fi
}

assert_false() {
    local description="$1"
    shift 2
    ((CHECKS++))
    if ! "$@"; then
        echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: ${description}"
    else
        echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: ${description} (expected failure, got success)"
        ((ERRORS++))
    fi
}

# assert_contains DESCRIPTION HAYSTACK NEEDLE
assert_contains() {
    local description="$1" haystack="$2" needle="$3"
    ((CHECKS++))
    if [[ "${haystack}" == *"${needle}"* ]]; then
        echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: ${description}"
    else
        echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: ${description} (expected to find '${needle}')"
        ((ERRORS++))
    fi
}

# ===============================================================================
# Load the installer's functions without running main() (guarded by the BASH_SOURCE-vs-0 check).
# ===============================================================================
# shellcheck source=/dev/null
source "${INSTALLER}"

# Make privileged/side-effecting helpers no-ops; unit tests never touch sudo, real package managers, or the network.
sudo_wrapper() { "$@"; }
install_packages() { :; }
install_dependencies() { :; }
log_message() {
    case "$1" in
    ERROR:*) echo "$1" >&2; exit 1 ;;
    esac
}
# shellcheck disable=SC2034  # read by functions sourced from the installer, not this file
LOG_FILE="$(mktemp)"
CURRENT_USER="$(id -un)"

# ===============================================================================
# is_version_greater
# ===============================================================================
print_header "is_version_greater"

assert_true  "2.0 > 1.0"            -- is_version_greater "2.0" "1.0"
assert_false "1.0 > 2.0 is false"   -- is_version_greater "1.0" "2.0"
assert_false "1.0 > 1.0 is false (equal)" -- is_version_greater "1.0" "1.0"
assert_true  "2.0.1 > 2.0.0"        -- is_version_greater "2.0.1" "2.0.0"
assert_false "non-numeric first arg is false" -- is_version_greater "abc" "1.0"
assert_false "non-numeric second arg is false" -- is_version_greater "1.0" "abc"

# ===============================================================================
# suggest_wxpython_wheel_index
# ===============================================================================
print_header "suggest_wxpython_wheel_index"

# Override the log_message stub locally to capture the message text for this section only.
captured_message=""
log_message() { captured_message="$1"; }

OS_ID_LIKE="ubuntu debian"
OS_VERSION_FULL="pop-22"
suggest_wxpython_wheel_index
assert_contains "ID_LIKE 'ubuntu debian' suggests the ubuntu-24.04 wheel index" "${captured_message}" "ubuntu-24.04"

OS_ID_LIKE="arch"
OS_VERSION_FULL="manjarolinux-25"
suggest_wxpython_wheel_index
assert_contains "ID_LIKE 'arch' also suggests the ubuntu-24.04 wheel index" "${captured_message}" "ubuntu-24.04"

OS_ID_LIKE="rhel fedora"
OS_VERSION_FULL="unknowndistro-1"
suggest_wxpython_wheel_index
assert_contains "unrecognized ID_LIKE falls back to the generic browse-manually message" "${captured_message}" "extras.wxpython.org"
((CHECKS++))
if [[ "${captured_message}" != *"ubuntu-24.04"* ]]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: unrecognized ID_LIKE does not suggest a specific wheel index"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: unrecognized ID_LIKE does not suggest a specific wheel index"
    ((ERRORS++))
fi

# shellcheck disable=SC2034  # read by suggest_wxpython_wheel_index, sourced from the installer
OS_ID_LIKE=""
# shellcheck disable=SC2034
OS_VERSION_FULL="unknown"
suggest_wxpython_wheel_index
assert_contains "empty ID_LIKE falls back to the generic browse-manually message" "${captured_message}" "extras.wxpython.org"

# Ubuntu derivatives report their base release in UBUNTU_CODENAME; the suggestion must follow it,
# because an ubuntu-24.04 wheel links against libtiff.so.6 and cannot load on a 22.04-based system.
# shellcheck disable=SC2034  # read by suggest_wxpython_wheel_index, sourced from the installer
OS_ID_LIKE="ubuntu debian"
# shellcheck disable=SC2034
OS_VERSION_FULL="zorin-17"
OS_CODENAME="jammy"
suggest_wxpython_wheel_index
assert_contains "jammy-based derivative suggests the ubuntu-22.04 wheel index" "${captured_message}" "ubuntu-22.04"

OS_CODENAME="noble"
suggest_wxpython_wheel_index
assert_contains "noble-based derivative suggests the ubuntu-24.04 wheel index" "${captured_message}" "ubuntu-24.04"

OS_CODENAME="bookworm"
suggest_wxpython_wheel_index
assert_contains "unmapped codename falls back to the newest LTS wheel index" "${captured_message}" "ubuntu-24.04"
# shellcheck disable=SC2034  # reset so later sections see a clean codename
OS_CODENAME=""

log_message() {
    case "$1" in
    ERROR:*) echo "$1" >&2; exit 1 ;;
    esac
}

# ===============================================================================
# ubuntu_release_from_codename
# ===============================================================================
print_header "ubuntu_release_from_codename"

assert_eq "focal maps to 20.04" "20.04" "$(ubuntu_release_from_codename focal)"
assert_eq "jammy maps to 22.04" "22.04" "$(ubuntu_release_from_codename jammy)"
assert_eq "noble maps to 24.04" "24.04" "$(ubuntu_release_from_codename noble)"
assert_eq "unknown codename maps to nothing" "" "$(ubuntu_release_from_codename bookworm)"
assert_eq "empty codename maps to nothing" "" "$(ubuntu_release_from_codename "")"

# ===============================================================================
# maybe_offer_studio
# ===============================================================================
print_header "maybe_offer_studio"

captured_message=""
log_message() { captured_message="$1"; }

STUDIO=false NON_INTERACTIVE=true PSYCHOPY_VERSION="2025.1.0"
maybe_offer_studio
assert_eq "pre-Studio-availability version is a no-op in non-interactive mode" "false" "${STUDIO}"

STUDIO=false NON_INTERACTIVE=false PSYCHOPY_VERSION="2025.1.0"
maybe_offer_studio
assert_eq "pre-Studio-availability version is a no-op in interactive mode" "false" "${STUDIO}"

STUDIO=true NON_INTERACTIVE=true PSYCHOPY_VERSION="2023.1.0"
maybe_offer_studio
assert_eq "--studio already set short-circuits regardless of version" "true" "${STUDIO}"

STUDIO=false STUDIO_OFFER_DECIDED=false NON_INTERACTIVE=true PSYCHOPY_VERSION="2026.1.0"
captured_message=""
maybe_offer_studio
assert_eq "Studio-available-but-pre-split version offers Studio (STUDIO stays false, non-interactive)" "false" "${STUDIO}"
assert_contains "pre-split NOTE mentions --studio as the opt-in" "${captured_message}" "--studio"
((CHECKS++))
if [[ "${captured_message}" != *"psychopy_app"* ]]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: pre-split NOTE does not mention psychopy_app"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: pre-split NOTE does not mention psychopy_app"
    ((ERRORS++))
fi

STUDIO=false STUDIO_OFFER_DECIDED=false NON_INTERACTIVE=true PSYCHOPY_VERSION="2026.2.1"
captured_message=""
maybe_offer_studio
assert_eq "non-interactive mode defaults to classic (STUDIO stays false)" "false" "${STUDIO}"
assert_contains "non-interactive NOTE mentions psychopy_app" "${captured_message}" "psychopy_app"
assert_contains "non-interactive NOTE mentions --studio as the opt-in" "${captured_message}" "--studio"

# A second call (as happens in --gui mode) must not re-prompt after a "classic" choice.
STUDIO=false STUDIO_OFFER_DECIDED=false NON_INTERACTIVE=true PSYCHOPY_VERSION="2026.2.1"
captured_message=""
maybe_offer_studio
captured_message=""
maybe_offer_studio
assert_eq "second call after a non-interactive 'classic' decision does not re-prompt" "" "${captured_message}"

prompt_user() { echo "${PROMPT_USER_RESPONSE}"; }
# Keeps the test offline.
studio_release_exists() { [[ " ${STUDIO_RELEASES} " == *" $1 "* ]]; }
STUDIO_RELEASES="2026.1.3 2026.2.1"

STUDIO=false STUDIO_OFFER_DECIDED=false NON_INTERACTIVE=false PSYCHOPY_VERSION="2026.2.1"
PROMPT_USER_RESPONSE="Install classic PsychoPy App"
maybe_offer_studio
assert_eq "interactive 'classic' choice leaves STUDIO false" "false" "${STUDIO}"

STUDIO=false STUDIO_OFFER_DECIDED=false NON_INTERACTIVE=false PSYCHOPY_VERSION="2026.2.1" STUDIO_VERSION="latest" CLASSIC_ONLY_ARGS=()
PROMPT_USER_RESPONSE="Install PsychoPy Studio instead"
maybe_offer_studio
assert_eq "interactive 'Studio' choice sets STUDIO true" "true" "${STUDIO}"
assert_eq "interactive 'Studio' choice installs the Studio release matching the offered version" "2026.2.1" "${STUDIO_VERSION}"

STUDIO=false STUDIO_OFFER_DECIDED=false NON_INTERACTIVE=false PSYCHOPY_VERSION="2026.1.0" STUDIO_VERSION="latest"
captured_message=""
maybe_offer_studio
assert_eq "'Studio' choice falls back to latest when that version has no Studio release" "latest" "${STUDIO_VERSION}"
assert_contains "falling back to latest Studio is announced" "${captured_message}" "latest PsychoPy Studio"

STUDIO=false STUDIO_OFFER_DECIDED=false NON_INTERACTIVE=false PSYCHOPY_VERSION="2026.1.3" STUDIO_VERSION="latest" CLASSIC_ONLY_ARGS=(--python-version --no-fonts)
captured_message=""
maybe_offer_studio
assert_contains "switching to Studio warns about the classic-only options that are now ignored" "${captured_message}" "--python-version --no-fonts"
# shellcheck disable=SC2034
CLASSIC_ONLY_ARGS=()
# Later process_arguments calls would reject a leftover Studio version.
STUDIO_VERSION=""
unset -f studio_release_exists

log_message() {
    case "$1" in
    ERROR:*) echo "$1" >&2; exit 1 ;;
    esac
}
# shellcheck disable=SC2034  # NON_INTERACTIVE read by maybe_offer_studio, sourced from the installer
output=$( (STUDIO=false; STUDIO_OFFER_DECIDED=false; NON_INTERACTIVE=false; PSYCHOPY_VERSION="2026.2.1"; PROMPT_USER_RESPONSE="Cancel installation"; maybe_offer_studio) 2>&1 )
rc=$?
assert_eq "interactive 'cancel' choice exits non-zero" "1" "${rc}"
assert_contains "interactive 'cancel' choice prints an ERROR" "${output}" "ERROR"

unset -f prompt_user

# ===============================================================================
# parse_requirements_file
# ===============================================================================
print_header "parse_requirements_file"

# Isolated fixture directory; rm -rf'd at the end of this section.
FIXTURE_DIR=$(mktemp -d)
REQ_FILE="${FIXTURE_DIR}/requirements.txt"
cat > "${REQ_FILE}" <<'EOF'
# a comment line, and a blank line follow

psychopy==2024.2.4
wxpython==4.2.3
numpy==1.26.4
pyglet==1.5.27
python-vlc==3.0.18
pywin32==306
somepkg @ file:///./wheels/somepkg-1.0-py3-none-any.whl
EOF
mkdir -p "${FIXTURE_DIR}/wheels"
touch "${FIXTURE_DIR}/wheels/somepkg-1.0-py3-none-any.whl"
# file:// wheel refs resolve relative to the requirements file's own directory; re-point the fixture there.
sed -i "s#file:///\./wheels/#file://${FIXTURE_DIR}/wheels/#" "${REQ_FILE}"

PYTHON_VERSION=""
WXPYTHON_VERSION=""
PSYCHOPY_VERSION=""
parse_requirements_file "${REQ_FILE}"

assert_eq "psychopy version extracted from requirements.txt" "2024.2.4" "${PSYCHOPY_VERSION}"
assert_eq "wxpython version extracted from requirements.txt" "4.2.3" "${WXPYTHON_VERSION}"
assert_contains "numpy pin passed through unchanged" "${REQUIREMENTSFILE_PACKAGES}" "numpy==1.26.4"
assert_contains "pyglet pin rewritten to >=" "${REQUIREMENTSFILE_PACKAGES}" "pyglet>=1.5.27"
assert_contains "python-vlc pin rewritten to >=" "${REQUIREMENTSFILE_PACKAGES}" "python-vlc>=3.0.18"
assert_contains "local wheel file:// reference passed through" "${REQUIREMENTSFILE_PACKAGES}" "somepkg @ file://"
((CHECKS++))
if [[ "${REQUIREMENTSFILE_PACKAGES}" != *"pywin32"* ]]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: Windows-only pywin32 excluded from install list"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: Windows-only pywin32 excluded from install list"
    ((ERRORS++))
fi
((CHECKS++))
if [[ "${REQUIREMENTSFILE_PACKAGES}" != *"psychopy=="* && "${REQUIREMENTSFILE_PACKAGES}" != *"wxpython=="* ]]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: psychopy/wxpython excluded from the extra-packages list (installed separately)"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: psychopy/wxpython excluded from the extra-packages list (installed separately)"
    ((ERRORS++))
fi
rm -rf "${FIXTURE_DIR}"

# ===============================================================================
# process_arguments
# ===============================================================================
print_header "process_arguments"

# Not run in a subshell: assert_* increments CHECKS/ERRORS in the caller's shell.
STUDIO=false PSYCHOPY_VERSION="" PYTHON_VERSION="" WXPYTHON_VERSION="" INSTALL_DIR=""
process_arguments --psychopy-version=2024.2.4 --python-version=3.10 --install-dir=/tmp/psychopy-test
assert_eq "process_arguments sets PSYCHOPY_VERSION" "2024.2.4" "${PSYCHOPY_VERSION}"
assert_eq "process_arguments sets PYTHON_VERSION" "3.10" "${PYTHON_VERSION}"
assert_eq "process_arguments sets INSTALL_DIR" "/tmp/psychopy-test" "${INSTALL_DIR}"

output=$( (process_arguments --python-version=notaversion) 2>&1 )
rc=$?
assert_eq "invalid --python-version exits non-zero" "1" "${rc}"
assert_contains "invalid --python-version prints an ERROR" "${output}" "ERROR"

output=$( (process_arguments --wxpython-wheel-index=https://example.com/ --build-wxpython) 2>&1 )
rc=$?
assert_eq "--wxpython-wheel-index + --build-wxpython conflict exits non-zero" "1" "${rc}"

output=$( (process_arguments --sudo-mode=bogus) 2>&1 )
rc=$?
assert_eq "invalid --sudo-mode exits non-zero" "1" "${rc}"

output=$( (process_arguments --log-level=bogus) 2>&1 )
rc=$?
assert_eq "invalid --log-level exits non-zero" "1" "${rc}"

STUDIO=false PSYCHOPY_VERSION="" PYTHON_VERSION=""
process_arguments --studio
assert_eq "process_arguments sets STUDIO" "true" "${STUDIO}"

STUDIO=false PSYCHOPY_VERSION="" PYTHON_VERSION=""
process_arguments --studio --studio-version=2026.1.2
assert_eq "process_arguments sets STUDIO_VERSION" "2026.1.2" "${STUDIO_VERSION}"

STUDIO=false STUDIO_VERSION="" PSYCHOPY_VERSION="" PYTHON_VERSION="" PSYCHOPY_APP_VERSION=""
process_arguments --psychopy-app-version=2026.2.0
assert_eq "process_arguments sets PSYCHOPY_APP_VERSION" "2026.2.0" "${PSYCHOPY_APP_VERSION}"

output=$( (STUDIO=false; process_arguments --studio --python-version=3.8) 2>&1 )
rc=$?
assert_eq "--studio + --python-version errors" "1" "${rc}"
assert_contains "--studio + --python-version prints an ERROR" "${output}" "ERROR"

output=$( (STUDIO=false; process_arguments --studio --additional-packages=foo) 2>&1 )
rc=$?
assert_eq "--studio + --additional-packages errors" "1" "${rc}"

output=$( (STUDIO=false; process_arguments --studio --psychopy-version=2026.2.1) 2>&1 )
rc=$?
assert_eq "--studio + --psychopy-version errors" "1" "${rc}"
assert_contains "--studio + --psychopy-version error mentions --studio-version" "${output}" "--studio-version"

output=$( (STUDIO=false; process_arguments --studio-version=2026.1.2) 2>&1 )
rc=$?
assert_eq "--studio-version without --studio errors" "1" "${rc}"

output=$( (STUDIO=false; process_arguments --remove-studio-settings) 2>&1 )
rc=$?
assert_eq "--remove-studio-settings without --studio errors" "1" "${rc}"

STUDIO=false PSYCHOPY_VERSION="" PYTHON_VERSION="" PSYCHOPY_APP_VERSION=""
process_arguments --studio --remove-studio-settings
assert_eq "process_arguments sets REMOVE_STUDIO_SETTINGS" "true" "${REMOVE_STUDIO_SETTINGS}"

output=$( (STUDIO=false; PSYCHOPY_APP_VERSION=""; process_arguments --studio --psychopy-app-version=2026.2.0) 2>&1 )
rc=$?
assert_eq "--studio + --psychopy-app-version errors" "1" "${rc}"

STUDIO=false STUDIO_VERSION="" REMOVE_STUDIO_SETTINGS=false PSYCHOPY_VERSION="" PSYCHOPY_APP_VERSION="" PYTHON_VERSION="" NO_FONTS=false
process_arguments --psychopy-version=2026.1.3 --python-version=3.10 --no-fonts
assert_eq "classic-only options given are remembered for a later switch to Studio" "--python-version --no-fonts" "${CLASSIC_ONLY_ARGS[*]}"
# shellcheck disable=SC2034
NO_FONTS=false

# ===============================================================================
# create_rerun_command
# ===============================================================================
print_header "create_rerun_command"

# Not run in a subshell: see the note above.
for key in "${!DEFAULT_OPTS[@]}"; do
    printf -v "${key}" '%s' "${DEFAULT_OPTS[${key}]}"
done
PSYCHOPY_VERSION="2024.2.4"
# shellcheck disable=SC2034  # read by create_rerun_command, sourced from the installer
BUILD_WXPYTHON=true
INSTALL_DIR="/custom/install/dir"
# shellcheck disable=SC2034
PSYCHOPY_APP_VERSION="2026.2.0"
# shellcheck disable=SC2034
REQUIREMENTS_FILE="/some/requirements.txt"
# shellcheck disable=SC2034
STUDIO_VERSION="2026.1.2"

# shellcheck disable=SC2034
STUDIO=false
rerun_cmd=$(create_rerun_command)
assert_contains "classic rerun command includes non-default psychopy-version" "${rerun_cmd}" "--psychopy-version=2024.2.4"
assert_contains "classic rerun command includes boolean flag for build-wxpython" "${rerun_cmd}" "--build-wxpython"
assert_contains "classic rerun command includes non-default install-dir" "${rerun_cmd}" "--install-dir=/custom/install/dir"
assert_contains "classic rerun command includes non-default psychopy-app-version" "${rerun_cmd}" "--psychopy-app-version=2026.2.0"
assert_contains "classic rerun command includes the requirements file" "${rerun_cmd}" "--requirements-file=/some/requirements.txt"
((CHECKS++))
if [[ "${rerun_cmd}" != *"--python-version="* ]]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: rerun command omits options left at their default"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: rerun command omits options left at their default"
    ((ERRORS++))
fi
((CHECKS++))
if [[ "${rerun_cmd}" != *"--studio"* ]]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: classic rerun command omits Studio-only options"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: classic rerun command omits Studio-only options (got '${rerun_cmd}')"
    ((ERRORS++))
fi

# GUI mode resolves the PsychoPy version before Studio is picked.
# shellcheck disable=SC2034
STUDIO=true
rerun_cmd=$(create_rerun_command)
assert_contains "Studio rerun command includes boolean flag for studio" "${rerun_cmd}" "--studio"
assert_contains "Studio rerun command includes non-default studio-version" "${rerun_cmd}" "--studio-version=2026.1.2"
assert_contains "Studio rerun command keeps shared options" "${rerun_cmd}" "--install-dir=/custom/install/dir"
for classic_flag in --psychopy-version --psychopy-app-version --build-wxpython --requirements-file; do
    ((CHECKS++))
    if [[ "${rerun_cmd}" != *"${classic_flag}"* ]]; then
        echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: Studio rerun command omits ${classic_flag}"
    else
        echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: Studio rerun command omits ${classic_flag} (got '${rerun_cmd}')"
        ((ERRORS++))
    fi
done
read -r -a rerun_args <<<"${rerun_cmd#* }"
# shellcheck disable=SC2034
output=$( (STUDIO=false; unset PSYCHOPY_VERSION PSYCHOPY_APP_VERSION PYTHON_VERSION WXPYTHON_VERSION WXPYTHON_WHEEL_INDEX ADDITIONAL_PACKAGES REQUIREMENTS_FILE STUDIO_VERSION; BUILD_WXPYTHON=false NO_FONTS=false REMOVE_PSYCHOPY_SETTINGS=false REMOVE_STUDIO_SETTINGS=false; process_arguments "${rerun_args[@]}") 2>&1 )
rc=$?
assert_eq "Studio rerun command is accepted by process_arguments" "0" "${rc}"
# shellcheck disable=SC2034
STUDIO=false
# shellcheck disable=SC2034
REQUIREMENTS_FILE=""

# ===============================================================================
# validate_user_list / get_real_users
# ===============================================================================
print_header "validate_user_list"

assert_true  "current user is a valid user" -- validate_user_list "${CURRENT_USER}"
assert_false "a made-up user is not valid" -- validate_user_list "definitely-not-a-real-user-xyz"

# ===============================================================================
# uses_psychopy_app_module
# ===============================================================================
print_header "uses_psychopy_app_module"

# The launcher, install step and final verification all gate on this predicate; a git-tag install never gets psychopy_app, so it must keep using the venv's entry point.
PSYCHOPY_GIT_TAG=false PSYCHOPY_VERSION="2026.2.1"
assert_true  "2026.2.1 from PyPI uses the psychopy_app module" -- uses_psychopy_app_module
PSYCHOPY_GIT_TAG=false PSYCHOPY_VERSION="2026.1.3"
assert_false "pre-split 2026.1.3 does not" -- uses_psychopy_app_module
PSYCHOPY_GIT_TAG=true PSYCHOPY_VERSION="2026.2.1"
assert_false "git-tag install of 2026.2.1 does not (psychopy_app is never installed for it)" -- uses_psychopy_app_module
PSYCHOPY_GIT_TAG=false PSYCHOPY_VERSION="git"
assert_false "'git' version does not" -- uses_psychopy_app_module
# shellcheck disable=SC2034  # read by uses_psychopy_app_module, sourced from the installer
PSYCHOPY_GIT_TAG=false

# ===============================================================================
# check_pypi_python_compatibility
# ===============================================================================
print_header "check_pypi_python_compatibility"

# Drive requires_python directly instead of hitting PyPI, so the bound parsing is what's under test.
# Run in a subshell: the global log_message stub exits on ERROR, which would kill the whole suite.
compat_ok() {
    local spec="$1" pyver="$2"
    (
        curl() { :; }
        jq() { printf '%s\n' "${spec}"; }
        PYTHON_VERSION="${pyver}"
        check_pypi_python_compatibility "pkg" "1.0"
    ) >/dev/null 2>&1
}

assert_true  "exclusive upper bound allows the version below it (<3.13, py3.12)" -- compat_ok "<3.13,>=3.10" "3.12"
assert_false "exclusive upper bound rejects its own version (<3.13, py3.13)" -- compat_ok "<3.13,>=3.10" "3.13"
assert_true  "inclusive upper bound allows its own version (<=3.12, py3.12)" -- compat_ok ">=3.8,<=3.12" "3.12"
assert_false "inclusive upper bound rejects the version above it (<=3.12, py3.13)" -- compat_ok ">=3.8,<=3.12" "3.13"
assert_false "lower bound rejects older Python (>=3.10, py3.9)" -- compat_ok ">=3.10" "3.9"
assert_true  "lower bound accepts the exact minimum (>=3.10, py3.10)" -- compat_ok ">=3.10" "3.10"
assert_true  "patch-level Python satisfies a minor-version bound (>=3.9, py3.10.12)" -- compat_ok ">=3.9" "3.10.12"

# ===============================================================================
# check_psychopy_python_floor
# ===============================================================================
print_header "check_psychopy_python_floor"

floor_ok() {
    (
        PSYCHOPY_VERSION="$1" PYTHON_VERSION="$2"
        check_psychopy_python_floor
    ) >/dev/null 2>&1
}
assert_false "psychopy 2025.1.0 + Python 3.8 is rejected" -- floor_ok "2025.1.0" "3.8"
assert_false "psychopy 2025.1.1 + Python 3.8.10 is rejected" -- floor_ok "2025.1.1" "3.8.10"
assert_true  "psychopy 2025.1.0 + Python 3.9 is allowed" -- floor_ok "2025.1.0" "3.9"
assert_true  "psychopy 2024.2.4 + Python 3.8 is allowed" -- floor_ok "2024.2.4" "3.8"
assert_true  "'git' version is not blocked" -- floor_ok "git" "3.8"

# ===============================================================================
# pick_legacy_wxpython_default
# ===============================================================================
print_header "pick_legacy_wxpython_default"

STUDIO=false PYTHON_VERSION="3.9" WXPYTHON_VERSION=""
pick_legacy_wxpython_default
assert_eq "Python 3.9 without a wxPython version gets the legacy default" "${WXPYTHON_LEGACY_VERSION}" "${WXPYTHON_VERSION}"
STUDIO=false PYTHON_VERSION="3.8.10" WXPYTHON_VERSION="4.2.2"
pick_legacy_wxpython_default
assert_eq "an explicit wxPython version is kept" "4.2.2" "${WXPYTHON_VERSION}"
STUDIO=false PYTHON_VERSION="3.10" WXPYTHON_VERSION=""
pick_legacy_wxpython_default
assert_eq "Python 3.10 is left to the normal default" "" "${WXPYTHON_VERSION}"

# The requirements file can set the Python version.
((CHECKS++))
parse_line=$(grep -n 'parse_requirements_file "${REQUIREMENTS_FILE}"' "${INSTALLER}" | tail -n1 | cut -d: -f1)
pick_line=$(grep -n '^\s*pick_legacy_wxpython_default$' "${INSTALLER}" | cut -d: -f1)
if [ -n "${parse_line}" ] && [ -n "${pick_line}" ] && [ "${pick_line}" -gt "${parse_line}" ]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: main picks the legacy wxPython default after parsing the requirements file"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: main picks the legacy wxPython default after parsing the requirements file (parse: ${parse_line}, pick: ${pick_line})"
    ((ERRORS++))
fi

# ===============================================================================
# github_wheel_os_tags
# ===============================================================================
print_header "github_wheel_os_tags"

OS_VERSION="linuxmint-22" OS_ID="linuxmint" OS_UBUNTU_BASE="24.04"
assert_eq "Mint 22 tries its own wheel, then the ubuntu-24 wheel" "linuxmint-22 ubuntu-24" "$(github_wheel_os_tags | xargs)"
OS_VERSION="pop-22" OS_ID="pop" OS_UBUNTU_BASE="22.04"
assert_eq "Pop!_OS 22 falls back to the ubuntu-22 wheel" "pop-22 ubuntu-22" "$(github_wheel_os_tags | xargs)"
OS_VERSION="ubuntu-24" OS_ID="ubuntu" OS_UBUNTU_BASE="24.04"
assert_eq "Ubuntu itself has no fallback" "ubuntu-24" "$(github_wheel_os_tags | xargs)"
OS_VERSION="debian-12" OS_ID="debian" OS_UBUNTU_BASE=""
assert_eq "non-Ubuntu distros have no fallback" "debian-12" "$(github_wheel_os_tags | xargs)"
# shellcheck disable=SC2034  # read by github_wheel_os_tags, sourced from the installer
OS_VERSION="unknown" OS_ID="" OS_UBUNTU_BASE=""
assert_eq "unknown OS yields no tags" "" "$(github_wheel_os_tags | xargs)"

# ===============================================================================
# Local cache of wxPython wheels built from source
# ===============================================================================
print_header "local wxPython wheel cache"

wheel_cache_tmp=$(mktemp -d)
# Runs a cache function with the network, uv and permission changes stubbed; the source tarball, wheel copy and lookup are real.
run_wheel_cache() {
    (
        export TMPDIR="${wheel_cache_tmp}"
        # shellcheck disable=SC2034  # read by functions sourced from the installer
        WXPYTHON_WHEEL_CACHE_DIR="${wheel_cache_tmp}/wxpython-wheels" UV_INSTALL_DIR="/uv" PSYCHOPY_DIR="/venv" \
            OS_VERSION="${2}" PYTHON_VERSION="${3}" WXPYTHON_VERSION="4.3.1" BUILD_WXPYTHON=false NON_INTERACTIVE=true
        set_shared_permissions() { :; }
        curl() {
            if [[ "$*" == *"pypi.org/pypi/wxpython/"* ]]; then
                echo '{"urls":[{"packagetype":"sdist","url":"https://files.example/wxpython-4.3.1.tar.gz"}]}'
                return
            fi
            local out="" src
            while [ $# -gt 0 ]; do [ "$1" = "-o" ] && out="$2"; shift; done
            src=$(mktemp -d)
            mkdir -p "${src}/wxpython-4.3.1" && touch "${src}/wxpython-4.3.1/pyproject.toml"
            tar -czf "${out}" -C "${src}" wxpython-4.3.1
        }
        log() {
            if [ "$1" = "/uv/uv" ]; then
                echo "UV: ${*:2}"
                if [ "$2" = "build" ]; then
                    local out=""
                    while [ $# -gt 0 ]; do [ "$1" = "-o" ] && out="$2"; shift; done
                    touch "${out}/wxpython-4.3.1-cp310-cp310-linux_x86_64.whl"
                fi
                return 0
            fi
            "$@"
        }
        if "${1}"; then echo "RC=0"; else echo "RC=1"; fi
    )
}

output=$(run_wheel_cache install_wxpython_from_local_cache cachyos-rolling 3.10)
assert_eq "an empty cache skips the tier without calling uv" "RC=1" "${output}"

output=$(run_wheel_cache build_wxpython cachyos-rolling 3.10)
assert_contains "the source build produces a wheel file instead of installing the source directory" "${output}" "UV: build "
assert_contains "the source build installs the built wheel" "${output}" "UV: pip install ${wheel_cache_tmp}/"
assert_true "the built wheel is kept in the per-OS cache" -- \
    test -f "${wheel_cache_tmp}/wxpython-wheels/cachyos-rolling/wxpython-4.3.1-cp310-cp310-linux_x86_64.whl"

output=$(run_wheel_cache install_wxpython_from_local_cache cachyos-rolling 3.10)
assert_contains "a reinstall finds the kept wheel" "${output}" "RC=0"
assert_contains "a reinstall installs from the per-OS cache" "${output}" "--find-links ${wheel_cache_tmp}/wxpython-wheels/cachyos-rolling"
output=$(run_wheel_cache install_wxpython_from_local_cache cachyos-rolling 3.9)
assert_eq "a wheel for another Python is not used" "RC=1" "${output}"
output=$(run_wheel_cache install_wxpython_from_local_cache fedora-41 3.10)
assert_eq "a wheel built on another OS release is not used" "RC=1" "${output}"
rm -rf "${wheel_cache_tmp}"

# ===============================================================================
# get_latest_studio_version
# ===============================================================================
print_header "get_latest_studio_version"

latest_studio=$(
    curl() {
        cat <<'EOF'
[{"tag_name":"2026.3.0rc1","prerelease":true,"draft":false,"assets":[{"name":"PsychoPy_Studio_2026.3.0rc1.AppImage"}]},
 {"tag_name":"2026.2.5","prerelease":false,"draft":false,"assets":[{"name":"psychopy-2026.2.5.tar.gz"}]},
 {"tag_name":"2026.2.4","prerelease":false,"draft":false,"assets":[{"name":"notes.txt"},{"name":"PsychoPy_Studio_2026.2.4.AppImage"},{"name":"PsychoPy_Studio_2026.2.4.AppImage.zsync"}]}]
EOF
    }
    get_latest_studio_version result_version
    # shellcheck disable=SC2154  # assigned through the nameref in get_latest_studio_version
    echo "${result_version}"
)
assert_eq "latest Studio skips pre-releases and releases without an AppImage" "2026.2.4" "${latest_studio}"

# ===============================================================================
# main() ignores exported option variables
# ===============================================================================
print_header "main environment isolation"

# OS detection is the first step after argument handling.
output=$(
    export PYTHON_VERSION="3.12.4" WXPYTHON_VERSION="4.2.0"
    check_connection() { :; }
    detect_os_version() { echo "REACHED_OS_DETECTION python='${PYTHON_VERSION}' studio='${STUDIO}'"; exit 0; }
    main --studio --non-interactive 2>&1
)
rc=$?
assert_eq "main --studio with exported PYTHON_VERSION gets past argument checks" "0" "${rc}"
assert_contains "exported PYTHON_VERSION is replaced by the default" "${output}" "python='${DEFAULT_OPTS[PYTHON_VERSION]}' studio='true'"

# ===============================================================================
# Regression guards for installer hygiene fixes
# ===============================================================================
print_header "Regression guards"

((CHECKS++))
if declare -p CURL_RETRY_OPTS CURL_DOWNLOAD_OPTS &>/dev/null; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: CURL_RETRY_OPTS and CURL_DOWNLOAD_OPTS are defined"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: CURL_RETRY_OPTS and CURL_DOWNLOAD_OPTS are defined"
    ((ERRORS++))
fi

((CHECKS++))
# Every real curl call should use one of the shared retry option arrays.
bare_curls=$(grep -nE '(^|[^_])curl (-|"https?)' "${INSTALLER}" \
    | grep -v 'command -v curl' \
    | grep -v 'CURL_RETRY_OPTS\|CURL_DOWNLOAD_OPTS' \
    | grep -v 'script_deps=' \
    | grep -v 'log_message' || true)
if [ -z "${bare_curls}" ]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: no curl invocations bypass the shared retry/timeout options"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: found curl invocations without retry/timeout options:"
    echo "${bare_curls}"
    ((ERRORS++))
fi

((CHECKS++))
if grep -q 'df -B1G --output=avail /tmp' "${INSTALLER}"; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: build_wxpython checks free (not total) /tmp space"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: build_wxpython checks free (not total) /tmp space"
    ((ERRORS++))
fi

((CHECKS++))
if ! grep -q 'UNIVERSIAL_PKG_FILE' "${INSTALLER}"; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: UNIVERSIAL_PKG_FILE typo has not regressed"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: UNIVERSIAL_PKG_FILE typo has not regressed"
    ((ERRORS++))
fi

((CHECKS++))
# The generated start_psychopy heredoc should never contain a literal backslash-quote.
# shellcheck disable=SC2016  # single-quoted sed pattern is intentional, not a missed expansion
heredoc_body=$(sed -n '/wrapper_script=\$(cat <<PSYCHOPY_WRAPPER_EOF/,/^PSYCHOPY_WRAPPER_EOF$/p' "${INSTALLER}")
if [[ "${heredoc_body}" != *'\"'* ]]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: no stray backslash-quotes in the generated uninstaller heredoc"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: no stray backslash-quotes in the generated uninstaller heredoc"
    ((ERRORS++))
fi

((CHECKS++))
if ! grep -qE '^\s+[a-zA-Z_][a-zA-Z0-9_]*\(\) \{' "${INSTALLER}"; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: no nested function definitions (all hoisted to top level)"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: no nested function definitions (all hoisted to top level)"
    ((ERRORS++))
fi

((CHECKS++))
if grep -q 'STUDIO}" = false \] && \[\[ ${options} != \*"Install font packages"' "${INSTALLER}"; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: GUI fonts inference is gated on classic installs (Studio must not get --no-fonts)"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: GUI fonts inference is gated on classic installs (Studio must not get --no-fonts)"
    ((ERRORS++))
fi

((CHECKS++))
if grep -q 'BASH_SOURCE\[0\]}" || "${BASH_SOURCE\[0\]}" == "${0}"' "${INSTALLER}"; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: entry-point guard still runs main for 'curl | bash'"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: entry-point guard still runs main for 'curl | bash'"
    ((ERRORS++))
fi

((CHECKS++))
if ! grep -qE '^\s*eval ' "${INSTALLER}"; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: no eval usage"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: no eval usage"
    ((ERRORS++))
fi

# ===============================================================================
# Summary
# ===============================================================================
echo -e "\n${BOLD}Summary:${NC}"
if [ "${ERRORS}" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All ${CHECKS} checks passed successfully!${NC}"
else
    echo -e "${RED}${BOLD}${ERRORS} out of ${CHECKS} checks failed.${NC}"
    exit 1
fi
