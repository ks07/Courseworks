#!/usr/bin/env python2
from __future__ import print_function
import math, random
import numpy as np
import matplotlib.pyplot as plt

def euler_iafn(f, y_0, t_0, t_e, h, y_th, y_reset):
    y_n = y_0

    t_vals = np.arange(t_0, t_e + h, h)
    y_vals = []
    spike_cnt = 0

    for n in t_vals:
        t_n = n
        #print("t: ", t_n, "\ty: ", y_n)
        y_vals.append(y_n)
        y_n = y_n + h * f(t_n, y_n)
        if y_n >= y_th:
            #print('t: ', t_n, 's => Spike!')
            y_n = y_reset
            spike_cnt += 1
    
    return (t_vals, y_vals, spike_cnt)

#
def integrate_and_fire_f(e_l__mV = -70, r_m__MOhm = 10, i__nA = 3.1, tau_m__ms = 10):
    def iaff(t, y):
        e_l = e_l__mV * (10**-3)
        r_m = r_m__MOhm * (10**6)
        i = i__nA * (10**-9)
        tau_m = tau_m__ms * (10**-3)
        v = y
        return (e_l - v + r_m * i) / tau_m
    return iaff

def leaky_integrate_and_fire(t, v_0__mV = -70, e_l__mV = -70, r_m__MOhm = 10, i__nA = 3.1, tau_m__ms = 10):
    v_0 = v_0__mV * (10**-3)
    e_l = e_l__mV * (10**-3)
    r_m = r_m__MOhm * (10**6)
    i_e = i__nA * (10**-9)
    tau_m = tau_m__ms * (10**-3)

    v_t = e_l + r_m * i_e + (v_0 - e_l - r_m * i_e) * math.exp(-t / tau_m)
    return v_t

def euler_iafn_t(f, y_0, t_0, t_e, h, y_th, y_reset):
    y_n = y_0
    y_m = y_0

    t_vals = np.arange(t_0, t_e + h, h)
    y_vals = []
    y_comp = []
    spike_cnt = 0

    t_spike = t_vals[0]
    for t_n in t_vals:

        #print("t: ", t_n, "\ty: ", y_n)
        y_vals.append(y_n)
        y_n = y_n + h * f(t_n, y_n)
        if y_n >= y_th:
            #print('t: ', t_n, 's => Spike!')
            y_n = y_reset
            spike_cnt += 1
        
        # Try using the actual equation instead of integrating
        y_comp.append(y_m)
        y_m = leaky_integrate_and_fire(t_n - t_spike)

        if y_m >= y_th:
            y_m = y_reset
            t_spike = t_n

    return (t_vals, y_vals, spike_cnt, y_comp)

def part1():
    print('Running Part 1')
    v_reset = -70 * (10**-3)
    y_0 = v_reset
    t_0 = 0.0
    t_e = 1.0
    h = 1 * (10 **-3)
    v_th = -40 * (10**-3)
    plot_vals = euler_iafn_t(integrate_and_fire_f(), y_0, t_0, t_e, h, v_th, v_reset)

    plt.plot(plot_vals[0], plot_vals[3], label='DT=1ms')
    plt.title('Plot of single neuron leaky integrate and fire model')
    plt.ylabel('Voltage Function V(t) (V)')
    plt.xlabel('Time t (s)')
    plt.legend(loc=4)
    plt.show()

def part2a():
    print('Running Part 2a')
    # Actual min i = 3.00000000000001 * (10**-9)???
    r_m = 10 * (10**6)
    e_l = -70 * (10**-3)
    v_th = -40 * (10**-3)
    i = (v_th - e_l) / r_m
    print('Min current I_e for action potential (A): ', i)
    return i

def part2b(min_i_e__A):
    print('Running Part 2b')
    v_reset = -70 * (10**-3)
    y_0 = v_reset
    t_0 = 0.0
    t_e = 1.0
    h = 1 * (10 **-3)
    v_th = -40 * (10**-3)
    
    min_i_e__nA = min_i_e__A / (10**-9)

    plot_vals = euler_iafn(integrate_and_fire_f(i__nA = min_i_e__nA - 0.1), y_0, t_0, t_e, h, v_th, v_reset)
    
    plt.plot(plot_vals[0], plot_vals[1], label='DT=1ms')
    plt.title('Plot of single neuron with lower than minimum input current')
    plt.ylabel('Voltage Function V(t) (V)')
    plt.xlabel('Time t (s)')
    plt.legend(loc=4)
    plt.show()

def part2():
    print('Running Part 2')
    min_i_e = part2a()
    part2b(min_i_e)

def part3():
    print('Running Part 3')
    v_reset = -70 * (10**-3)
    y_0 = v_reset
    t_0 = 0.0
    t_e = 1.0
    h = 1 * (10 **-3)
    v_th = -40 * (10**-3)

    i_vals__nA = np.arange(2, 5.1, 0.1)
    srate_vals__Hz = []

    for i_e__nA in i_vals__nA:
        spike_cnt = euler_iafn(integrate_and_fire_f(i__nA = i_e__nA), y_0, t_0, t_e, h, v_th, v_reset)[2]
        srate_vals__Hz.append(spike_cnt / (t_e - t_0))
        print('i_e__nA:', i_e__nA, '\tSpike count:', spike_cnt, '\tSpike rate:', srate_vals__Hz[-1])

    # TODO: Better plot
    plt.plot(i_vals__nA, srate_vals__Hz, label='Spike Rate')
    plt.title('Plot of firing rate as function of input current')
    plt.ylabel('Spike Rate (Hz)')
    plt.xlabel('Input Current I_e (nA)')
    plt.legend(loc=4)
    plt.show()

def part4x(e_s, s_type):
    # Neuron params
    tau_m = 20 * (10**-3)
    e_l = -70 * (10**-3)
    v_reset = -80 * (10**-3)
    v_th = -54 * (10**-3)
    r_m_i_e = 18 * (10**-3)
    # Synapse params
    r_m_g_s = 0.15
    p_max = 0.5
    tau_s = 10 * (10**-3)
    dt = 1 * (10**-3)

    v_0 = [random.uniform(v_reset, v_th) for _ in range(2)]
    
    t_0 = 0
    t_e = 1
    t_vals = np.arange(t_0, t_e + dt, dt)

    def p_s(t, t_f):
        """" Get the opening probability of a synapse at time t with last pre-synaptic spike at time t_f. """
        return p_max * math.exp((t_f - t) / tau_s)
    
    def neuron_model(t, v, t_f):
        """ Gets dV/dt of the neuron with a synaptic input. """
        return (e_l - v - r_m_g_s * p_s(t, t_f) * (v - e_s) + r_m_i_e) / tau_m

    v_vals = [ [] , [] ]
    #          \_____/

    # Need to link two neurons/functions, so can't re-use old method
    # TODO: Maybe we can - function like objects and overloads, or cheat with some globals
    v_n = list(v_0)
    t_f = [ 0.0 , 0.0 ]
    for t_n in t_vals:
        for n in range(0, 2): # Two neurons
            v_vals[n].append(v_n[n])
            v_n[n] = v_n[n] + dt * neuron_model(t_n, v_n[n], t_f[n ^ 1])
            if v_n[n] >= v_th:
                v_n[n] = v_reset
                t_f[n] = t_n
            

    plt.plot(t_vals, v_vals[0], label='Neuron A')
    plt.plot(t_vals, v_vals[1], label='Neuron B')
    plt.title('Plot of two neurons with ' + s_type + ' synaptic connections; leaky integrate and fire model')
    plt.ylabel('Voltage Function V(t) (V)')
    plt.xlabel('Time t (s)')
    plt.legend(loc=4)
    plt.show()

def part4():
    print('Running Part 4')

    # Excitatory (a)
    e_s_a = 0 * (10**-3)
    # Inhibitory (b)
    e_s_b = -80 * (10**-3)

    print('Running Part 4a')
    part4x(e_s_a, 'excitatory')
    print('Running Part 4b')
    part4x(e_s_b, 'inhibitory')

def part5():
    print('Running Part 5')
    v_reset = -70 * (10**-3)
    v_0 = v_reset
    t_0 = 0.0
    t_e = 3.0
    h = 1 * (10 **-3)
    v_th = -40 * (10**-3)

    e_l = -70 * (10**-3)
    r_m = 10 * (10**6)
    i = 3.1 * (10**-9)
    tau_m = 10 * (10**-3)

    g_0 = 0
    e_k = -80 * (10**-3)
    delta_g = 0.01 * (10**-6)
    tau_slow = 200 * (10**-3)
    
    def g_k_model(t, g_k):
        return -g_k/tau_slow

    def neuron_model(t, v, g_k):
        """ Gets dV/dt of the neuron with a slow potassium current. """
        i_k = g_k * (e_k - v)

        return (e_l - v + r_m * (i + i_k)) / tau_m

    v_vals = []
    g_vals = []
    v_n = v_0
    t_f = 0.0
    g_k = g_0

    dt = 1 * (10**-3)
    t_vals = np.arange(t_0, t_e + dt, dt)

    for t_n in t_vals:
        v_vals.append(v_n)
        v_n = v_n + dt * neuron_model(t_n, v_n, g_k)
        if v_n >= v_th:
            v_n = v_reset
            t_f = t_n
            # Spike should boost g_k instantaneously
            g_k += delta_g
        else:
            # No spike, should decay g_k
            g_k = g_k + dt * g_k_model(t_n, g_k)
        g_vals.append(g_k)
    
    plt.plot(t_vals, v_vals, label='DT=1ms')
    plt.title('Plot of single neuron leaky integrate and fire model')
    plt.ylabel('Voltage Function V(t) (V)')
    plt.xlabel('Time t (s)')
    plt.legend(loc=4)
    plt.show()
    plt.plot(t_vals, g_vals, label='DT=1ms')
    plt.title('Plot of single neuron leaky integrate and fire model')
    plt.ylabel('g_k')
    plt.xlabel('Time t (s)')
    plt.legend(loc=4)
    plt.show()

if __name__ == '__main__':
    part1()
    #part2()
    #part3()
    #part4()
    part5()
