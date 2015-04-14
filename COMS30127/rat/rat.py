#!/usr/bin/env python2
from __future__ import print_function
from bisect import bisect_left
import math, random
import numpy as np
import matplotlib.pyplot as plt

def run():
    times = [int(z.strip()) for z in open('time.csv').readlines()]
    x = [float(z.strip()) for z in open('x.csv').readlines()]
    y = [float(z.strip()) for z in open('y.csv').readlines()]
    neuron = [[int(z.strip()) for z in open('neuron{0}.csv'.format(n)).readlines()] for n in range(1,5)]
    print(len(times), len(x), len(y), [len(n) for n in neuron])

    # tpos should be sorted already, but we should make sure.
    tpos = zip(times, x, y)
    pos = zip(x, y)
    data = {time: (x, y) for (time, x, y) in zip(times, x, y)}
    print(len(data), data[times[-1]])
    neuron_pos_plot(times, x, y, data, neuron)

# Need to find the nearest time point
def binsearch_time_pos(times, target_time):
    i = bisect_left(times, target_time)
    if times[i] == target_time:
        return (i, i)
    else:
        return (i-1, i)

def neuron_pos_plot(times, x, y, data, neuron):
    fig, ax = plt.subplots(1, 4)

    # For now lets just take the left answer.
    neuron_nearest_times = [[binsearch_time_pos(times, t)[0] for t in n] for n in neuron]
    #print(len(neuron_nearest_times), len(neuron_nearest_times[0]), times[neuron_nearest_times[0][0][0]], times[neuron_nearest_times[0][0][1]])

    # Just do neuron 0
    x_n = [[x[i] for i in neuron_nearest_times[n]] for n in range(len(neuron))]
    y_n = [[y[i] for i in neuron_nearest_times[n]] for n in range(len(neuron))]
    
    colors = ('b', 'g', 'r', 'k')
    for n in range(len(neuron)):
        ax[n].scatter(x_n[n], y_n[n], c=colors[n]);
#    fig.show()
    plt.show()


if __name__ == '__main__':
    run()
