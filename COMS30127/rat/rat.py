#!/usr/bin/env python2
from __future__ import print_function
from bisect import bisect_left
import itertools as itt
import numpy as np
import matplotlib.pyplot as plt

def gather_input():
    times = [int(z.strip()) for z in open('time.csv').readlines()]
    x = [float(z.strip()) for z in open('x.csv').readlines()]
    y = [float(z.strip()) for z in open('y.csv').readlines()]
    neuron = [[int(z.strip()) for z in open('neuron{0}.csv'.format(n)).readlines()] for n in range(1,5)]
    return (times, x, y, neuron)

def run():
    times, x, y, neuron = gather_input()

    neuron_pos_plot(times, x, y, neuron)
    neuron_autocorrelograms_plot(neuron)
    neuron_correlograms_plot(neuron)

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
        # Bin the differences, skip 0 as it's not particularly interesting, use 100 step => 10ms buckets
        # => 10ms buckets from 10ms to 1000ms
        bins = np.arange(100, 10000, 100)
        n, bins, _ = ax[i].hist(diffs, bins=bins)
        ax[i].set_title('Neuron {0}'.format(i + 1))
        ax[i].set_xlabel('delta t (e-4 s)')
        ax[i].set_ylabel('Spike Count')
        ax[i].ticklabel_format(style='sci', axis='x', scilimits=(0,0))

    plt.show()

def neuron_correlograms_plot(neurons):
    fig, axs = plt.subplots(4, 4, sharex=True)

    fig.suptitle('Neuron Firing Cross-Correlograms')

    for ax, (neuronA, neuronB) in itt.izip(axs.flat, itt.product(neurons, repeat=2)):
        # Try doing it manually by calculating the difference.
        diffs = [ta - tb for ta in neuronA for tb in neuronB]
        # Bin the differences, skip 0 as it's not particularly interesting
        bins = np.arange(100, 10000, 100)
        n, bins, _ = ax.hist(diffs, bins=bins)
        #ax[i].set_title('Neuron {0}'.format(i + 1))
        #ax.set_xlabel('delta t (e-4 s)')
        #ax.set_ylabel('Spike Count')
        ax.ticklabel_format(style='sci', axis='x', scilimits=(0,0))

    # Label the columns with the neuron number
    for i, ax in enumerate(axs[0]):
        ax.set_title('Neuron {0}'.format(i + 1))

    # Label only the bottom row with the x axis label
    for ax in axs[-1]:
        ax.set_xlabel('delta t (e-4 s)')

    # Label the rows with the neuron number, by abusing the y axis label
    for i, ax in enumerate(zip(*axs)[0]):
        ax.set_ylabel('Neuron {0}\nSpike Count'.format(i + 1))

    plt.get_current_fig_manager().window.showMaximized()
    # Any adjustments to the layout fall flat as soon as the window is resized, even like this.
    plt.tight_layout()
    plt.subplots_adjust(top=0.95)
    plt.show()

if __name__ == '__main__':
    run()
