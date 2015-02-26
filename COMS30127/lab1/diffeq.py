#!/bin/env python2
from __future__ import print_function
from math import *
import numpy as np
import matplotlib as mp

def euler(y, start, end, h):
    t_0 = start
    y_0 = y(t_0, 0) # This f param is funky
    
    y_n = y_0
    y_np1 = 0
    
    for n in np.arange(start, end, h):
        print(y_n, n)
        t_n = n
        y_np1 = y_n + h * y(t_n, y_n)
        y_n = y_np1
        
        
    print(y_n);

def eq1(t, f):
    if (t == 0):
        return 0
    else:
        return f**2 - 3 * f + exp(-t)

def eqt(t, f):
    if (t == 0):
        return 1
    else:
        return 2 - exp(-4 * t) - 2 * f

def part1():
    start = 0
    end = 3
    h = 0.01
    euler(eq1, start, end, h)

def t():
    start = 0
    end = 0.5
    h = 0.1
    euler(eqt, start, end, h)

if __name__ == '__main__':
    t()
