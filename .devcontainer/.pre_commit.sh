#!/bin/bash
# Run all checks
"$(git rev-parse --show-toplevel)/test/syntax_checks.sh"
check_result=$?

# exit if any check failed
if [ $check_result -ne 0 ]; then
    exit $check_result
fi

# update date if psychopy_linux_installer is staged for commit
if git diff --cached --name-only | grep -q '^psychopy_linux_installer$'; then
    sed -i "s/^#  Last Updated:.*/#  Last Updated:  $(date +%Y-%m-%d)/" "$(git rev-parse --show-toplevel)/psychopy_linux_installer"
    git add "$(git rev-parse --show-toplevel)/psychopy_linux_installer"
fi