#!/bin/bash

all_tests=$(fgrep -rl ';;;test;;;' *.ass)
for t in $all_tests; do
    echo $t
    ./assembler.py < $t
    yes 'c 900' | rlwrap ./sim.py out.bin out_test.py | tail -n 12
done
