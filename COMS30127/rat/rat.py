#!/usr/bin/env python2
from __future__ import print_function
import math, random
import numpy as np
import matplotlib.pyplot as plt

def run():
    times = [int(z.strip()) for z in open('time.csv').readlines()]
    x = [float(z.strip()) for z in open('x.csv').readlines()]
    y = [float(z.strip()) for z in open('y.csv').readlines()]
    neuron = [[int(z.strip()) for z in open('neuron{0}.csv'.format(n)).readlines()] for n in range(1,5)]
    print(len(times), len(x), len(y), [len(n) for n in neuron])

if __name__ == '__main__':
    run()
