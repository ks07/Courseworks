#!/usr/bin/env python

from itertools import izip_longest
import sys, numpy

def explode_ins(ins):
    # Can't unpack directly here as nop has no args!
    split = ins.strip().split(' ', 1)
    op = split[0].strip()
    args = [] if op == 'nop' else split[1].strip().split(',')
    return (op, args);

def implode_ins(op, args):
    return op + ' ' + ",".join(str(a) for a in args);

def code_size(code):
    # TODO: don't expand ld here, need to do in hw.
    if code.startswith("la ") or code.startswith("ad "):
        return 2
    return 1

def expand_pseudo(code, labels):
    """ If given a pseudocode instruction, expand it to actual instructions. Data pseudo-instructions (e.g. .word) are ignored here, as they are just literals. Returns a list. """
    if code.startswith("la "):
        # la translates to movi and moui
        _, args = explode_ins(code)
        return [
            implode_ins('movi', [args[0], labels[args[1]] & 0xFFFF]),
            implode_ins('moui', [args[0], labels[args[1]] >> 16])
        ]
    elif code.startswith("ad "):
        # ad (address diff) puts the difference between two labels into a reg, with an offset
        _, args = explode_ins(code)
        args[3] = int(args[3], 0)
        # Limited to 16 bits, should never need more!
        return [
            implode_ins('movi', [args[0], (abs(labels[args[1]] - labels[args[2]]) - args[3]) & 0xFFFF]),
            implode_ins('moui', [args[0], (abs(labels[args[1]] - labels[args[2]]) - args[3]) >> 16])
        ]
    else:
        return [code];

def pass1(source):
    """ First pass needs to calculate the address of labels. We're also going to abuse it to replace pseudo-instructions. """
    labels = {}
    ins_list = []
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
                    size = code_size(code) # Handle pseudo-instructions
                    addr += size
                    ins_list.append(code) # Code expanded if necessary later.
    return (ins_list, labels)

# Messy... unfortunately I have lots of co-prime sized chunks.
formats = {
    'nop': (0,0),
    'add': (1,'r','r','r',0),
    'sub': (1,'r','r','r',1),
    'mul': (1,'r','r','r',2),
    'and': (1,'r','r','r',3),
    'or': (1,'r','r','r',4),
    'xor': (1,'r','r','r',5),
    'mov': (1,'r','r',6),
    'shl': (1,'r','r','r',8),
    'shr': (1,'r','r','r',9),
    'addi': (2,'r','i',0),
    'subi': (2,'r','i',1),
    'muli': (2,'r','i',2),
    'andi': (2,'r','i',3),
    'ori': (2,'r','i',4),
    'xori': (2,'r','i',5),
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

def gen_ins(ins, labels):
    """ Formats instruction. """
    op, args = explode_ins(ins)
    if op == '.word':
        # Special pseudo-instruction that is just a literal to load into memory at startup
        val = int(args[0], 0)
    else:
        frmt = formats[op]
        # Get bits 31-26
        shift = 26
        val = frmt[0] << shift
        for elem, arg in izip_longest(frmt[1:], args):
            if elem == 'r':
                shift -= 5
                to_add = int(arg[1:])
            elif elem == 'i':
                shift -= 16
                # FIXME: ???
                if arg in labels:
                    to_add = labels[arg]
                else:
                    # base 0 parses like a literal
                    to_add = int(arg, 0)
            else:
                shift = 0
                to_add = elem
            val |= (to_add << shift)
    # val now (hopefully) contains a 32-bit instruction.
    assert val >> 32 == 0
    
    return val
    

def pass2(ins_list, labels):
    """ Second pass to generate object code. """
    addr = 0
    # 1MB memory
    memory = numpy.zeros(262250, dtype=numpy.uint32)
    # Open debug output
    dbg_out = open('out.dbg', 'w')
    for orig_ins in ins_list:
        expanded = expand_pseudo(orig_ins, labels)
        if len(expanded) > 1:
            # Print the original to debug if it's a pseudo-instruction
            dbg_out.write(orig_ins)
            dbg_out.write("\n")
        for ins in expanded:
            dbg_out.write(ins)
            dbg_out.write("\n")
            out = gen_ins(ins, labels)
            # Write debug out.
            dbg_out.write("{0:08x} {0:032b}\n".format(out, out))
            # Store binary out.
            memory[addr] = out
            addr += 1
    # Mark the end of the file for debugging purposes.
    dbg_out.write("{0:08x} {0:032b}\n".format(0xDEADBEEF, 0xDEADBEEF))
    memory[addr] = 0xDEADBEEF
    memory.tofile('out.bin')
    dbg_out.close()

def main():
    source = sys.stdin.readlines()
    ins_list, labels = pass1(source)
    pass2(ins_list, labels)

if __name__ == '__main__' :
    main()
