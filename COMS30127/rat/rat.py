#!/usr/bin/env python2
from __future__ import print_function
from bisect import bisect_left
import itertools as itt
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
    neuron_pos_plot(times, x, y, neuron)
    neuron_autocorrelograms_plot(neuron)

# Need to find the nearest time point
def binsearch_time_pos(times, x, y, target_time):
    i = bisect_left(times, target_time)
    if times[i] == target_time:
        return (x[i], y[i])
    else:
        # Interpolate between the points... let's simply take a biased average
        lo_t = times[i]
        hi_t = times[i+1]
        t_diff = hi_t - lo_t

        t_split = target_time - lo_t

        assert t_split < t_diff

        t_frac = float(t_split) / float(t_diff)
        
        border_x = [x[i], x[i+1]]
        border_y = [y[i], y[i+1]]

        x_diff = border_x[1] - border_x[0]
        y_diff = border_y[1] - border_y[0]

        interp_x = border_x[0] + (t_frac * x_diff)
        interp_y = border_y[0] + (t_frac * y_diff)

        return (interp_x, interp_y)

def neuron_pos_plot(times, x, y, neuron):
    fig, ax = plt.subplots(3, 4, gridspec_kw={'height_ratios':[10,10,1]}) # Requires matplotlib 1.4 => use pip

    neuron_pos = [[binsearch_time_pos(times, x, y, t) for t in n] for n in neuron]
    
    fig.suptitle('Neuron Firing Positions')

    colors = ('b', 'g', 'r', 'y')
    for n, pos_list in enumerate(neuron_pos):
        # Scatter
        ax[0][n].scatter([pos[0] for pos in pos_list], [pos[1] for pos in pos_list], c=colors[n])
        ax[0][n].set_ylim([0,250])
        ax[0][n].set_xlim([0,300])
        ax[0][n].set_title('Neuron {0}'.format(n + 1))
        ax[0][n].set_xlabel('X Position')
        ax[0][n].set_ylabel('Y Position')
        
        # Heatmap/hexplot
        im = ax[1][n].hexbin([pos[0] for pos in pos_list], [pos[1] for pos in pos_list], bins='log', gridsize=30)
        ax[1][n].set_xlabel('X Position')
        ax[1][n].set_ylabel('Y Position')
        cb = fig.colorbar(im, cax=ax[2][n], orientation='horizontal')
        cb.set_label('log10(N)')

    plt.show()

def neuron_autocorrelograms_plot(neurons):
    fig, ax = plt.subplots(1, 4)

    fig.suptitle('Neuron Firing Auto-Correlograms')

    for i, neuron in enumerate(neurons):
        # Try doing it manually by calculating the difference.
        diffs = [ta - tb for ta in neuron for tb in neuron]
        # Bin the differences
        bins = np.arange(0, 1000, 10)
        n, bins, _ = ax[i].hist(diffs, bins=bins)
        ax[i].set_title('Neuron {0}'.format(i + 1))
        ax[i].set_xlabel('delta t (e-4 s)')
        ax[i].set_ylabel('Spike Count')

    plt.show()

if __name__ == '__main__':
    run()
