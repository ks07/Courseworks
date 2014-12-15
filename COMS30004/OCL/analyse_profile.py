#!/usr/bin/env python
import csv

invoc_cnt={}
gpu_stats={}
cpu_stats={}

with open('opencl_profile_0.csv', 'rb') as csvfile:
    profreader = csv.reader(csvfile, delimiter=',')
    next(profreader, None) # Skip header
    for row in profreader:
        if row[0] in gpu_stats:
            invoc_cnt[row[0]] += 1
            gpu_stats[row[0]] += float(row[1])
            cpu_stats[row[0]] += float(row[2])
        else:
            invoc_cnt[row[0]] = 1
            gpu_stats[row[0]] = float(row[1])
            cpu_stats[row[0]] = float(row[2])

#print "Total time spent per kernel/operation:"
print "kernel , gpu_time , cpu_time , invocations , avg_time_gpu"
for meth in gpu_stats:
    print meth, ",", gpu_stats[meth], ",", cpu_stats[meth], ",", invoc_cnt[meth], ",", gpu_stats[meth]/invoc_cnt[meth]
