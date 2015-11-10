#!/usr/bin/env python

# Instruction format details for encode and decode - used by sim and assembler!

# First element is the 6 bit opcode.
# Following elements are 5 bits for registers, 16 bit immediates.
# Final integer literal fills the remainder of the word
# r = register read (may also be output); o = register output (no read); i = immediate
FORMATS = {
    'nop': (0,0),
    'add': (1,'o','r','r',0),
    'sub': (1,'o','r','r',1),
    'mul': (1,'o','r','r',2),
    'and': (1,'o','r','r',3),
    'or': (1,'o','r','r',4),
    'xor': (1,'o','r','r',5),
    'mov': (1,'o','r',6),
    'shl': (1,'o','r','r',8),
    'shr': (1,'o','r','r',9),
    'addi': (2,'r','i',0),
    'subi': (2,'r','i',1),
    'muli': (2,'r','i',2),
    'andi': (2,'r','i',3),
    'ori': (2,'r','i',4),
    'xori': (2,'r','i',5),
    'movi': (2,'r','i',6),
    'moui': (2,'r','i',7),
    'ld': (3,'o','r','r',0),
    'st': (4,'r','r','r',0),
    'br': (5,'i',0),
    'bz': (6,'r','i',0),
    'bn': (7,'r','i',0),
    'beq': (8,'r','r','i'),
    'bge': (9,'r','r','i'),
}
