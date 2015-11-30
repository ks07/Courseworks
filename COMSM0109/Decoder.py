#!/usr/bin/env python

import numpy as np
from StatefulComponent import StatefulComponent
from Instruction import Instruction
from InstructionFormats import FORMATS
from itertools import repeat

class Decoder(StatefulComponent):
    """ A decode unit. State is the current instruction in this stage, and an indicator for load stalling. """

    NO_LD = 64
    
    def __init__(self, regfile, width):
        # Width gives the number of instructions that are held and decoded.
        self.RLD_IND = width
        self.EMP_IND = width + 1 # Index of empty counter, tells how many instructions from fetch to accept.
        self._state = np.zeros(width + 2, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)
        # Decode stage reads from register file.
        self._reg = regfile
        self._width = width
        self._state[self.EMP_IND] = self._width

    def __str__(self):
        #return 'Decoding now: {0:08x} => {1:s}'.format(self._state[0], str(self._decode(self._state[0])))
        return 'Decoder buffer: ' + str(self._state[:self.RLD_IND])

    def advstate(self):
        # TODO: should call super
        np.copyto(self._state, self._state_nxt, casting='no')
        # Need to handle dependency checking
    
    def queueInstructions(self, toDecodeList):
        # Put at end of waiting list in state.
        accept = self._state[self.EMP_IND]
        print 'queued, accepting:', accept
        print self._state_nxt
        print toDecodeList
        toDecodeList = toDecodeList[:accept]
        print toDecodeList
        self._state_nxt[self.RLD_IND-len(toDecodeList):self.RLD_IND] = toDecodeList
        print self._state_nxt

    def pipelineClear(self):
        """ Called when the stage needs clearing due to a branch misprediction. """
        self._state_nxt[:self._width] = 0 # Clear the instruction buffers
        self._state_nxt[self.RLD_IND] = self.NO_LD # Don't need to bubble for load
        self._state_nxt[self.EMP_IND] = self._width;
    
    def decode(self):
        """ Decodes current inputs, returns as many independent instructions as possible up to width. """
        ready = []
        for ii in range(self._width):
            ins = self._decode(self._state[ii])

            # Store the output reg.
            #TODO: Nicer check of load
            ldreg = ins.getOutReg() if ins.getOutReg() is not None and ins.getOpc().startswith('ld') else self.NO_LD
            self.update(self.RLD_IND, ldreg)

            # If the previously decoded ins was a load, check if there is a RAW dependency.
            # if self._state[self.RLD_IND]] < 32:
            if self._state[self.RLD_IND] in ins.getRegValMap():
                print '* v---Inserting a bubble to avoid data hazard from RAW dependency after a load.' #TODO: Print order
                # Need to stall both this and fetch stages to wait for the bubble.
                self.update(ii, self._state[ii]) #TODO: This could be problematic if stages are re-ordered!
                #return Instruction.NOP() #TODO: Can the interaction between stages be handled by the stages, not CPU?
            if not ins._invregs:
                # If any of the operands are not ready, the ins is not ready (blocking issue)
                ready.append(ins)
                # Need to mark the pending write in the register scoreboard.
                print ins, 'OUT REG:', ins.getOutReg()
                if ins.getOutReg() is not None:
                    self._reg.markScoreboard(ins.getOutReg(), True);
            else:
                break

        # Need to shift down by the number of instructions we are passing out.
        count = len(ready)
        self._state_nxt[:self.RLD_IND-count] = self._state[count:self.RLD_IND]
        self._state_nxt[self.RLD_IND-count:self.RLD_IND] = [0] * (count)

        # Set the accept count
        self._state[self.EMP_IND] = len(ready) # JEEPERS CREEPERS
        
        print 'Ready:', ready
        if len(ready) < 2:
            print 'DECODER IS BLOCKING/DELAYING'
        else:
            print 'DECODER OK'
        return ready

    def _decode(self, word):
        """ Decodes a given word; return an Instruction object represented by word. """
        group = word >> 26 # All instructions start with a possibly unique 6 bit ID
        diff = word & 0x1F # Where ins not identified uniquely by group, the 5 LSBs should differentiate

        possible = [(opc, frmt) for opc, frmt in FORMATS.iteritems() if frmt[0] == group]

        if not possible:
            # If invalid instruction, either the program is going to branch before this
            # is executed, the program has a bug, or the sim has a bug!
            # The first possibility is not an error, so replace instruction with something we can pass!
            return Instruction.NOP(word)
        elif len(possible) == 1:
            opc, frmt = possible[0]
            if diff != frmt[-1] and not isinstance(frmt[-1], basestring):
                return Instruction.NOP(word)
            # The Instruction constructor deals with splitting args.
            return Instruction(opc, frmt, word, self._reg)
        else:
            for opc, frmt in possible:
                if frmt[-1] == diff:
                    return Instruction(opc, frmt, word, self._reg)
            raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', word,  '{:032b}'.format(word))
