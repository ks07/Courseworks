#!/usr/bin/env python

from itertools import izip_longest
import sys

def pass1(source):
    """ First pass needs to calculate the address of labels. """
    labels = {}
    addr = 0
    for line in source:
        if line.strip() and line.lstrip()[0] != ';':
            line_parts = line.strip().split(';', 1)
            comment = line_parts[1] if len(line_parts) > 1 else ''
            content = line_parts[0]

            if content:
                content_parts = content.strip().split(':', 1)
                code = content_parts[0].rstrip()
                if len(content_parts) > 1:
                    # Colon found, must have a label. No dupe checking!
                    label = content_parts[0].rstrip()
                    code = content_parts[1].lstrip()
                    labels[label] = addr
                if code:
                    # If there is code, increment addr.
                    addr += 1
    return (ins_list, labels)

# This is terrible... unfortunately I have lots of 5 bit chunks.
formats = {
    'nop': (0,0),
    'add': (1,'r','r','r',0),
    'sub': (1,'r','r','r',1),
    'mul': (1,'r','r','r',2),
    'movi': (2,'r','i',6),
    'moui': (2,'r','i',7),
    'ld': (3,'r','r','r',0),
    'st': (4,'r','r','r',0),
    'br': (5,'i',0),
    'bz': (6,'r','i',0),
    'bn': (7,'r','i',0),
    'beq': (8,'r','r','i'),
    'bge': (9,'r','r','i'),
}

def gen_ins(ins, args, labels):
    """ Formats instruction. """
    frmt = formats[ins]
    # Get bits 31-26
    val = frmt[0] << 26
    shift = 26
    to_add = 0
    for elem, arg in izip_longest(frmt[1:], None):
        if elem == 'r':
            shift -= 5
            to_add = int(arg[1:])
        elif elem == 'i':
            shift -= 16
            to_add = arg
        else:
            shift = 0
            to_add = arg
        val |= (to_add << shift)

def pass2(ins_list, labels):
    """ Second pass to generate object code. """
    for addr, ins in enumerate(ins_list):
        

def main():
    source = sys.stdin.readlines()
    parsed = parse(source)
    ins_list, labels = pass1(source)


if __name__ == '__main__' :
    main()
