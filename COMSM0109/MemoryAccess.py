#!/usr/bin/env python

from Instruction import Instruction

class MemoryAccess(object):
    """ The memory access stage. We do have state, but nothing in a Numpy array! """

    def __init__(self, mem):
        self._ins = Instruction.NOP()
        self._ins_nxt = Instruction.NOP()
        # Need a handle to memory
        self._mem = mem
        # Need a handle to the execute unit, for operand bypass
#        self._executor = executor;

    def __str__(self):
        return 'Now in memory access: {0:s}'.format(str(self._ins))

    def updateInstruction(self, ins):
        """ Puts an instruction on the stage input. """
        self._ins_nxt = ins;

    def memaccess(self):
        """ Performs the memory access stage. """
        memop = self._ins.getMemOperation()
        if memop and not self._ins.robpoisoned: # Poisoned instructions usually have bogus values
            addr,write = memop
            if write:
                #print '* Memory access stage wrote {0:d} to address {1:d} for {2:s}.'.format(write, addr, str(self._ins))
                #self._mem[addr] = write
                # ROB PERFORMS WRITES NOW FOR CONSISTENCY
                pass
            else:
                val = self._mem[addr]
                print '* Memory access stage read {0:d} from address {1:d} for {2:s}.'.format(val, addr, str(self._ins))
                self._ins.setWBOutput(self._ins.getOpr()[0], val) # TODO: This will be broken by weird loads!

#                self._executor.bypassBack(2, self._ins.getOpr()[0], val);
        return self._ins


    def advstate(self):
        """ Advances state, like a StatefulComponent. """
        self._ins = self._ins_nxt
