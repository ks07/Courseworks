#!/bin/bash

# Make the format more machine readable by stripping out the inline headers and the trailing comments.
grep -Ev '^#.*' opencl_profile_0.log | sed -r 's/method=\[ ([^0-9].*) \] gputime=\[ ([0-9]+\.[0-9]+) \] cputime=\[ ([0-9]+\.[0-9]+) \](| occupancy=\[ )([0-9]\.[0-9]+)?( \] | $)/\1,\2,\3,\5/' > opencl_profile_0.csv

./analyse_profile.py | column -s ' , ' -t
