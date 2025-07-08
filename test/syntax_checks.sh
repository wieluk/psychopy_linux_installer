#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'
PASS_SYMBOL="✓"
FAIL_SYMBOL="✗"

# Disable colors if output is not a terminal.
if [[ ! -t 1 ]]; then
    RED=''
    GREEN=''
    BLUE=''
    BOLD=''
    NC=''
    PASS_SYMBOL=""
    FAIL_SYMBOL=""
fi

# Determine the repository root.
PARENT_DIR=$(git rev-parse --show-toplevel)

ERRORS=0
CHECKS=0

# Updated print_header function that accepts an optional file path.
print_header() {
    echo -e "\n${BLUE}${BOLD}$1${NC}"
    if [ -n "$2" ]; then
        echo -e "${BLUE}File: $2${NC}"
    fi
    echo -e "${BLUE}$(printf '%.0s-' $(seq 1 ${#1}))${NC}\n"
}

report_result() {
    if [ "$1" -eq 0 ]; then
        echo -e "${GREEN}${PASS_SYMBOL} PASS${NC}: $2\n"
    else
        echo -e "${RED}${FAIL_SYMBOL} FAIL${NC}: $2\n"
        ((ERRORS++))
    fi
    ((CHECKS++))
}

# Run bash syntax check
print_header "Checking Bash syntax" "$PARENT_DIR/psychopy_linux_installer"
bash -n "$PARENT_DIR/psychopy_linux_installer"
report_result $? "Bash syntax check"

# Run shellcheck
print_header "Running ShellCheck" "$PARENT_DIR/psychopy_linux_installer"
shellcheck -x "$PARENT_DIR/psychopy_linux_installer"
report_result $? "ShellCheck analysis"

# Run bashate
print_header "Running Bashate" "$PARENT_DIR/psychopy_linux_installer"
bashate "$PARENT_DIR/psychopy_linux_installer" --ignore E006
report_result $? "Bashate style check"

# Check spelling in README
print_header "Checking spelling in README.md" "$PARENT_DIR/README.md"
codespell "$PARENT_DIR/README.md"
report_result $? "README.md spell check"

# Check spelling in script
print_header "Checking spelling in psychopy_linux_installer" "$PARENT_DIR/psychopy_linux_installer"
codespell "$PARENT_DIR/psychopy_linux_installer"
report_result $? "psychopy_linux_installer spell check"

# Check variable formatting in psychopy_linux_installer (ignoring PATH and name)
print_header "Checking variable formatting (non-curly braces)" "$PARENT_DIR/psychopy_linux_installer"
grep -n -P '\$(?!\{)(?!(PATH|name)\b)[a-zA-Z_][a-zA-Z0-9_]*' "$PARENT_DIR/psychopy_linux_installer" | \
  awk -v file="$PARENT_DIR/psychopy_linux_installer" -F: '{print file ":" $1 ":1: Non-curly brace: "$0; print ""}'
grep_exit_code=${PIPESTATUS[0]}
report_result "$([ "$grep_exit_code" -eq 1 ] && echo 0 || echo 1)" "Non-curly brace variable check"

# Print summary
echo -e "\n${BOLD}Summary:${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All $CHECKS checks passed successfully!${NC}"
else
    echo -e "${RED}${BOLD}$ERRORS out of $CHECKS checks failed.${NC}"
    exit 1
fi
