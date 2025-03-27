#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ERRORS=0
CHECKS=0

print_header() {
    echo -e "\n${BLUE}${BOLD}$1${NC}"
    echo -e "${BLUE}$(printf '%.0s-' $(seq 1 ${#1}))${NC}\n"
}

report_result() {
    if [ "$1" -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2\n"
    else
        echo -e "${RED}✗ FAIL${NC}: $2\n"
        ((ERRORS++))
    fi
    ((CHECKS++))
}

# Run bash syntax check
print_header "Checking Bash syntax"
bash -n psychopy_linux_installer
report_result $? "Bash syntax check"

# Run shellcheck
print_header "Running ShellCheck"
shellcheck -x psychopy_linux_installer
report_result $? "ShellCheck analysis"

# Run bashate
print_header "Running Bashate"
bashate psychopy_linux_installer --ignore E006
report_result $? "Bashate style check"

# Check spelling in README
print_header "Checking spelling in README.md"
codespell README.md
report_result $? "README.md spell check"

# Check spelling in script
print_header "Checking spelling in psychopy_linux_installer"
codespell psychopy_linux_installer
report_result $? "psychopy_linux_installer spell check"

# Print summary
echo -e "\n${BOLD}Summary:${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All $CHECKS checks passed successfully!${NC}"
else
    echo -e "${RED}${BOLD}$ERRORS out of $CHECKS checks failed.${NC}"
    exit 1
fi
