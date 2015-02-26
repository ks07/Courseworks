#!/usr/bin/env python2
from __future__ import print_function
import numpy as np
import matplotlib.pyplot as plt

def euler_iafn(f, y_0, t_0, t_e, h, y_th, y_reset):
    y_n = y_0

    t_vals = np.arange(t_0, t_e + h, h)
    y_vals = []

    for n in t_vals:
        t_n = n
        print("t: ", t_n, "\ty: ", y_n)
        y_vals.append(y_n)
        y_n = y_n + h * f(t_n, y_n)
        if y_n >= y_th:
            print('Spike!')
            y_n = y_reset
    
    return (t_vals, y_vals)

#dv/dt
def integrate_and_fire_f(t, y):
    e_l = -70 * (10**-3)
    r_m = 10 * (10**6)
    i = 3.1 * (10**-9)
    v = y
    tau_m = 10 * (10**-3)
    return (e_l - v + r_m * i) / tau_m

def part1():
    v_reset = -70 * (10**-3)
    print(v_reset)
    y_0 = v_reset
    t_0 = 0.0
    t_e = 1.0
    h = 1 * (10 **-3)
    v_th = -40 * (10**-3)
    plot_vals = euler_iafn(integrate_and_fire_f, y_0, t_0, t_e, h, v_th, v_reset)
    
    plt.plot(plot_vals[0], plot_vals[1], label='DT=1ms')
    plt.title('Plot of single neuron leaky integrate and fire model')
    plt.ylabel('Voltage Function V(t) (V)')
    plt.xlabel('Time t (s)')
    plt.legend(loc=4)
    plt.show()

if __name__ == '__main__':
    part1()
