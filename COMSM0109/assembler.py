#!/bin/env python

import sys

def parse(source):
    """ Cuts out all lines to be ignored from the source, returns the pruned source list. """
    return [line.rstrip() for line in source if line.strip() and line.lstrip()[0] != ';']

def pass1(source):
    """ First pass needs to calculate the address of labels. """
    labels = {}
    addr = 0
    for line in source:
        if line.strip() and line.lstrip()[0] != ';':
            line_parts = line.strip().split(';', 1)
            comment = line_parts[1] if len(line_parts) > 1 else ''
            
            if line[-1] == ':':
                # Found a label
                label = line[:-1]
                labels[label] = addr
    return labels

def main():
    source = sys.stdin.readlines()
    parsed = parse(source)
    print pass1(parsed)


if __name__ == '__main__' :
    main()
