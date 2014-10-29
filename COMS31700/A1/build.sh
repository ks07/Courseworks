#!/bin/sh
vlog -work calc1_black_box/ example_calc1_tb.v \
&& vsim -c calc1_black_box.example_calc1_tb
