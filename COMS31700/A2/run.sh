#!/bin/sh
irun calc1_sn_env.e calc1_sn.v -gui -access rw -coverage all -covtest my_code_coverage_results -covoverwrite -snprerun "config cover -write_model=ucm" -nosncomp > /dev/null 2>&1 &
