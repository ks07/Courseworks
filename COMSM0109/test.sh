#!/bin/bash

all_tests=$(fgrep -rl ';;;test;;;' *.ass)
passed=()
failed=()
for t in $all_tests; do
    echo $t
    ./assembler.py < $t
    if yes 'c 50' | timeout --foreground 30 ./sim.py out.bin out_test.py > /dev/null; then
	passed+=("$t")
    else
	failed+=("$t")
    fi
done
echo "Passed ${#passed[*]}: ${passed[*]}"
echo "Failed ${#failed[*]}: ${failed[*]}"
