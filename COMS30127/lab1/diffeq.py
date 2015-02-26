#!/usr/bin/env python2
from __future__ import print_function
from math import *
import numpy as np
import matplotlib as mp
import matplotlib.pyplot as plt

def euler(f, y_0, t_0, t_e, h):
    y_n = y_0

    t_vals = np.arange(t_0, t_e + h, h)
    y_vals = []

    for n in t_vals:
        t_n = n
        print("t: ", t_n, "\ty: ", y_n)
        y_vals.append(y_n)
        y_n = y_n + h * f(t_n, y_n)
    
    return (t_vals, y_vals)

def eq1_f(t, y):
    return y**2 - 3 * y + exp(-t)

def part1():
    y_0 = 0
    t_0 = 0
    t_e = 3
    h = 0.01
    plot_vals = euler(eq1_f, y_0, t_0, t_e, h_i)
    
    plt.plot(plot_vals[0], plot_vals[1], label='DT=0.01')
    plt.title('Plot of df/dt = f^2 - 3f + exp(-t); f(0)=0')
    plt.ylabel('Function f(t)')
    plt.xlabel('Time t')
    plt.legend()
    plt.show()

def part2():
    y_0 = 0
    t_0 = 0
    t_e = 3
    h = [0.01, 0.1, 0.5, 1]
    plot_vals = []

    for h_i in h:
        plot_vals.append(euler(eq1_f, y_0, t_0, t_e, h_i))
    
    plt.plot(plot_vals[0][0], plot_vals[0][1], 
             plot_vals[1][0], plot_vals[1][1], 
             plot_vals[2][0], plot_vals[2][1], 
             plot_vals[3][0], plot_vals[3][1])
    plt.title('Plot of df/dt = f^2 - 3f + exp(-t); f(0)=0')
    plt.ylabel('Function f(t)')
    plt.xlabel('Time t')
    plt.legend(('DT=0.01','DT=0.1','DT=0.5','DT=1'))
    plt.show()


def eqt_f(t, y):
    return 2 - exp(-4 * t) - 2 * y

def t():
    t_0 = 0
    y_0 = 1
    t_e = 0.5
    h = 0.1
    return euler(eqt_f, y_0, t_0, t_e, h)

if __name__ == '__main__':
    part2()
