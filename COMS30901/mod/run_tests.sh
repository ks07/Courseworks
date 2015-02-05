#!/bin/bash

make &&

for i in {1..4}; do
    echo "./modmul stage${i} <stage${i}.input > tmp_out"
    ./modmul "stage${i}" < "stage${i}.input" > tmp_out
    diff -s tmp_out "stage${i}.output"
done
