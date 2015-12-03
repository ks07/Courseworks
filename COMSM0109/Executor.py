#!/usr/bin/env python

import numpy as np
from StatefulComponent import StatefulComponent
from Instruction import Instruction

class Executor(StatefulComponent):
    """ An execution unit, or ALU, with a bit of wrapping. Additional state as Instruction object. """

    RBD1_IND = 32
    RBD2_IND = 33
    RBD3_IND = 34

    def __init__(self, cpu):
        # Holds values to be written by an instruction just executed. Last 3 values are bitfields
        # for dirty markers for the previous 3 cycles (32 = exec (prev), 33 = acc (prev again), 34 = wb)
        self._state = np.zeros(35, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)

        # Additional state!
        self._ins = Instruction.NOP()
        self._ins_nxt = Instruction.NOP()

        # Reluctantly store a handle to the cpu
        self._cpu = cpu;

    def advstate(self):
        """ Need to update the additional state that we can't store as ints. """
        self._ins = self._ins_nxt
        return super(self.__class__, self).advstate();

    def updateInstruction(self, decoded):
        """ Puts an instruction on the stage input. """
        self._ins_nxt = decoded
        
    def invalidateInstruction(self):
        """ Invalidates the incoming instruction. """
        self._ins_nxt = Instruction.NOP()
        
    def bypassBack(self, age, reg, val):
        """ Inserts a value back into the bypass registers, from a later stage. """
        # TODO: We might only need support for age == 2, so forget generalising for now
        if age != 2:
            raise ValueError('Unimplemented bypassBack age!', age);
        
        if not self._state_nxt[self.RBD1_IND] & reg:
            self._state_nxt[reg] = val
        # Need to pass this back 2 steps
        self._state_nxt[self.RBD2_IND] |= (1 << reg)

    def __str__(self):
        return 'Executing now: {0:s}'.format(str(self._ins))
        
    def execute(self):
        ins = self._ins

        print '* Execute stage is performing {0:s}'.format(str(ins))

        # Not sure if we want to keep this logic here...
        opc = ins.getOpc()
        opr = ins.getOpr()
        val = ins.getVal()

        bbf = self._state[self.RBD1_IND] | self._state[self.RBD2_IND] | self._state[self.RBD3_IND]
        for ri,vi in ins.getRegValMap().iteritems():
            # Need to check if a value has been bypassed (would be done by decoder in real cpu)
            if bbf & (1 << ri):
                print '* ...using the value of r{0:d} ({1:d}) bypassed back from the previous cycle.'.format(ri, self._state[ri])
                val[vi] = self._state[ri];

        outReg = opr[0] if len(opr) > 0 else None# True for almost all opcodes
        outAddr = None

        if opc == 'nop':
            outReg = None
            pass
        elif opc == 'dnop':
            print 'WARNING: EXECUTING A DNOP!' # TODO: We rely on this causing exceptions for tests!
            #raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', ins.getWord())
        elif opc == 'halt':
            self._cpu.halt()
        elif opc == 'add':
            outVal = val[0] + val[1]
        elif opc == 'sub':
            outVal = val[0] - val[1]
        elif opc == 'mul':
            outVal = val[0] * val[1]
        elif opc == 'and':
            outVal = val[0] & val[1]
        elif opc == 'or':
            outVal = val[0] | val[1]
        elif opc == 'xor':
            outVal = val[0] ^ val[1]
        elif opc == 'mov':
            outVal = val[0]
        elif opc == 'shl':
            outVal = val[0] << val[1]
        elif opc == 'shr':
            outVal = val[0] >> val[1]
        elif opc == 'addi':
            outVal = val[0] + opr[1]
        elif opc == 'subi':
            outVal = val[0] - opr[1]
        elif opc == 'muli':
            outVal = val[0] * opr[1]
        elif opc == 'andi':
            outVal = val[0] & opr[1]
        elif opc == 'ori':
            outVal = val[0] | opr[1]
        elif opc == 'xori':
            outVal = val[0] ^ opr[1]
        elif opc == 'movi':
            outVal = opr[1]
        elif opc == 'moui':
            outVal = val[0] | (opr[1] << 16)
        elif opc == 'ld':
            # TODO: De-dupe the r_base + r_offset logic?
            # TODO: Nicer handling of val/mem/writeback in this case
#            outVal = self._mem[ val[1] + val[2] ]
            outReg = None # TODO: lol, not true
            outAddr = val[0] + val[1]
            outVal = None # TODO: plz
        elif opc == 'st':
            outReg = None
            outAddr = val[1] + val[2]
            outVal = val[0] #TODO: Oh please no
#            self._mem[ val[1] + val[2] ] = val[0]
        elif opc == 'br':
            # Should do nothing as we will always predict this!
            outReg = None
            self._cpu._branch(True, ins.predicted, opr[0])
            print "* ...but br is always taken, so this is a nop!"

            pass
        elif opc == 'bz':
            outReg = None
            self._cpu._branch(val[0] == 0, ins.predicted, opr[1])
        elif opc == 'bn':
            # Need to switch on the top bit (rather than <0), as we're storing as unsigned!
            outReg = None
            self._cpu._branch(val[0] >> 31, ins.predicted, opr[1])
        elif opc == 'beq':
            outReg = None
            self._cpu._branch(val[0] == val[1], ins.predicted, opr[2])
        elif opc == 'bge':
            outReg = None
            self._cpu._branch(val[0] >= val[1], ins.predicted, opr[2])
        else:
            outReg = None
            print "WARNING: Unimplemented opcode:", opc

        # Need to keep all the old bypass values
        self._state_nxt = self._state
        # Need to move bypass 2,3 up
        # Need to do 3 stages as explained here:
        # http://courses.cs.washington.edu/courses/cse378/02sp/sections/section7-1.html
        self._state_nxt[self.RBD3_IND] = self._state[self.RBD2_IND]
        self._state_nxt[self.RBD2_IND] = self._state[self.RBD1_IND]
        self._state_nxt[self.RBD1_IND] = 0

        if not outReg is None:
            ins.setWBOutput(outReg, outVal)
            # Need to pass back to bypass stage
            self._state_nxt[outReg] = outVal
            # Set the bitfield for bypass 1
            self._state_nxt[self.RBD1_IND] = (1 << outReg)
        if not outAddr is None:
            ins.setMemOperation(outAddr, outVal)
        return ins
