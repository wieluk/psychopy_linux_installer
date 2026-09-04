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

STUDIO=false STUDIO_OFFER_DECIDED=false NON_INTERACTIVE=false PSYCHOPY_VERSION="2026.2.1"
PROMPT_USER_RESPONSE="Install classic PsychoPy App"
maybe_offer_studio
assert_eq "interactive 'classic' choice leaves STUDIO false" "false" "${STUDIO}"

STUDIO=false STUDIO_OFFER_DECIDED=false NON_INTERACTIVE=false PSYCHOPY_VERSION="2026.2.1"
PROMPT_USER_RESPONSE="Install PsychoPy Studio instead"
maybe_offer_studio
assert_eq "interactive 'Studio' choice sets STUDIO true" "true" "${STUDIO}"

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

STUDIO=false PSYCHOPY_VERSION="" PYTHON_VERSION=""
process_arguments --studio --remove-studio-settings
assert_eq "process_arguments sets REMOVE_STUDIO_SETTINGS" "true" "${REMOVE_STUDIO_SETTINGS}"

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
STUDIO=true
# shellcheck disable=SC2034
STUDIO_VERSION="2026.1.2"
# shellcheck disable=SC2034
PSYCHOPY_APP_VERSION="2026.2.0"
# shellcheck disable=SC2034
REQUIREMENTS_FILE=""

rerun_cmd=$(create_rerun_command)
assert_contains "rerun command includes non-default psychopy-version" "${rerun_cmd}" "--psychopy-version=2024.2.4"
assert_contains "rerun command includes boolean flag for build-wxpython" "${rerun_cmd}" "--build-wxpython"
assert_contains "rerun command includes non-default install-dir" "${rerun_cmd}" "--install-dir=/custom/install/dir"
assert_contains "rerun command includes boolean flag for studio" "${rerun_cmd}" "--studio"
assert_contains "rerun command includes non-default studio-version" "${rerun_cmd}" "--studio-version=2026.1.2"
assert_contains "rerun command includes non-default psychopy-app-version" "${rerun_cmd}" "--psychopy-app-version=2026.2.0"
((CHECKS++))
if [[ "${rerun_cmd}" != *"--python-version="* ]]; then
    echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: rerun command omits options left at their default"
else
    echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: rerun command omits options left at their default"
    ((ERRORS++))
fi

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
