#!/usr/bin/env python2
from __future__ import print_function
from bisect import bisect_left
import itertools as itt
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors
itertools = itt
def gather_input():
    times = [int(z.strip()) for z in open('time.csv').readlines()]
    x = [float(z.strip()) for z in open('x.csv').readlines()]
    y = [float(z.strip()) for z in open('y.csv').readlines()]
    neuron = [[int(z.strip()) for z in open('neuron{0}.csv'.format(n)).readlines()] for n in range(1,5)]
    return (times, x, y, neuron)

def run():
    times, x, y, neuron = gather_input()

#    neuron_pos_plot(times, x, y, neuron)
#    neuron_autocorrelograms_plot(neuron)
#    neuron_correlograms_plot(neuron)
    neuron_firerate_pos_plot(times, x, y, neuron)
#    neuron_firerate_plot(min(times), max(times), neuron)

# Need to find the nearest time point
def binsearch_time_pos(times, x, y, target_time, inc_time = False):
    i = bisect_left(times, target_time)
    if times[i] == target_time:
        if inc_time:
            return (x[i], y[i], target_time)
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

        if inc_time:
            return (interp_x, interp_y, target_time)
        return (interp_x, interp_y)

def neuron_pos_plot(times, x, y, neuron):
    fig, ax = plt.subplots(3, 4, gridspec_kw={'height_ratios':[10,10,1]}) # Requires matplotlib 1.4 => use pip

    neuron_pos = [[binsearch_time_pos(times, x, y, t) for t in n] for n in neuron]
    
    fig.suptitle('Neuron Firing Positions', fontsize=16)

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

    # Would savefig here, but it's too much work to get the formatting/layout correct
    plt.show()

def neuron_autocorrelograms_plot(neurons):
    fig, ax = plt.subplots(1, 4)

    fig.suptitle('Neuron Firing Auto-Correlograms', fontsize = 16)

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
    fig, axs = plt.subplots(1, 2)

    fig.suptitle('Neuron Firing Cross-Correlograms', fontsize = 16)

    for ax, (neuronA, neuronB) in itt.izip(axs, [(neurons[0],neurons[2]), (neurons[1],neurons[3])]):
        print(len(neuronA), len(neuronB))
        # Try doing it manually by calculating the difference.
        diffs = [ta - tb for ta in neuronA for tb in neuronB]
        # Bin the differences, skip 0 as it's not particularly interesting
        bins = np.arange(-10000, 10000, 100)
        n, bins, _ = ax.hist(diffs, bins=bins)
        #ax[i].set_title('Neuron {0}'.format(i + 1))
        #ax.set_xlabel('delta t (e-4 s)')
        #ax.set_ylabel('Spike Count')
        ax.ticklabel_format(style='sci', axis='x', scilimits=(0,0))
        ax.set_xlim(-10000, 10000)
        ax.set_ylabel('Spike Count')
        ax.set_xlabel('delta t (e-4 s)')

    # Label the columns with the neuron number
    #for i, ax in enumerate(axs[0]):
    axs[0].set_title('Neuron {0} v {1}'.format(1,3))
    axs[1].set_title('Neuron {0} v {1}'.format(2,4))

    plt.get_current_fig_manager().window.showMaximized()
    # Any adjustments to the layout fall flat as soon as the window is resized, even like this.
    plt.tight_layout()
    plt.subplots_adjust(top=0.95)
    plt.show()

def pairwise(iterable):
    "s -> (s0,s1), (s1,s2), (s2, s3), ..."
    a, b = itertools.tee(iterable)
    next(b, None)
    return itertools.izip(a, b)

def neuron_firerate_pos_plot(times, x, y, neurons):
    fig, ax = plt.subplots(3, 4, gridspec_kw={'height_ratios':[10,10,1]}) # Requires matplotlib 1.4 => use pip

    neuron_pos = [[binsearch_time_pos(times, x, y, t, True) for t in n] for n in neurons]
    
    fig.suptitle('Neuron Firerate Regions', fontsize=16)

    colors = ('b', 'g', 'r', 'y')
    for n, pos_list in enumerate(neuron_pos):
        # Split the world into 3x3 grid
        
        x_tops = np.linspace(0,300,9)
        y_tops = np.linspace(0,250,9)

        bins = [ [ [] for _ in x_tops ] for _ in y_tops ]
        bin_means = [ [None] * len(x_tops) for _ in y_tops ]

        for e in pos_list:
            x, y, time = e
            my_x = 1
            my_y = 0

            for x_i, x_top in enumerate(x_tops):
                if x < x_top:
                    my_x = x_i
                    break
            for y_i, y_top in enumerate(y_tops):
                if y < y_top:
                    my_y = y_i
                    break
            my_bin = bins[my_x][my_y]
            my_bin.append(time)

        # Loop through bins and calculate the time difference
        
        for x, somecol in enumerate(bins):
            for y, somebin in enumerate(somecol):
                bin_diffs = []
                for time_a, time_b in pairwise(somebin):
                    t_diff = time_b - time_a
                    bin_diffs.append(t_diff)
                if not bin_diffs:
                    bin_means[x][y] = 0
                else:
                    bin_means[x][y] = np.mean(bin_diffs)

        plt.hist2d([x - 1 for x in x_tops]*len(y_tops),[y - 1 for y in y_tops]*len(x_tops),weights=np.array(bin_means, order='F').flatten(order='F'),bins=[x_tops,y_tops],)
        plt.show()


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

    # Would savefig here, but it's too much work to get the formatting/layout correct
    plt.show()

def neuron_firerate_plot(mintime, maxtime, neurons):
    fig, ax = plt.subplots(1, 4)

    fig.suptitle('Neuron Firing Rate Histogram')

    # Bin in 1 second intervals
    all_bins = np.arange(mintime, maxtime, 10000)

    for i, neuron in enumerate(neurons):
        ax[i].hist(neuron, bins=all_bins)
        ax[i].set_xlabel('Time (e-4 s)')
        ax[i].set_ylabel('Spike Count')
        ax[i].set_title('Neuron {0}'.format(i + 1))

    plt.show()

if __name__ == '__main__':
    run()
