#!/usr/bin/env python

import numpy as np
from StatefulComponent import StatefulComponent
from Instruction import Instruction
from InstructionFormats import FORMATS
from itertools import repeat, chain

class Decoder(StatefulComponent):
    """ A decode unit. State is the current instruction in this stage, and an indicator for load stalling. """

    NO_LD = 64
    
    def __init__(self, regfile, width):
        # Width gives the number of instructions that are held and decoded.
        self.RLD_IND = width
        self.EMP_IND = width + 1 # Index of empty counter, tells how many instructions from fetch to accept.
        self.BRW_IND = width + 2 # Index of branch wait indicator, if set we should issue nothing until branch is resolved.
        self._state = np.zeros(width + 3, dtype=np.uint32)
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

    def branchResolved(self):
        """ Called when a branch has been resolved (made it out of execute). Unblocks issue. """
        self._state_nxt[self.BRW_IND] = 0
    
    def decode(self):
        """ Decodes current inputs, returns as many independent instructions as possible up to width. """
        readyALU = []
        readyBRU = []
        readyLSU = []
        maxALU = 2;
        maxBRU = 1;
        maxLSU = 1;
        if False and self._state[self.BRW_IND]:
            # Waiting for a branch to resolve, block issue.
            pass
        else:
            # No branches currently waiting, try to issue.
            for ii in range(self._width):
                ins = self._decode(self._state[ii])
                
                if not ins._invregs:
                    # If any of the operands are not ready, the ins is not ready (blocking issue)
                    if ins.isBranch():
                        if self._state[self.BRW_IND]:
                            # Need to block here, as we're only letting one branch through at a time
                            break
                        else:
                            # Need to put into a different queue
                            readyBRU.append(ins)
                        # Don't want to dispatch anything else after the branch
                        break
                    elif ins.isHalt():
                        # Want to dispatch on it's own.
                        if readyBRU or readyALU:
                            break
                        else:
                            # Put halts on the branch unit queue
                            readyBRU.append(ins)
                    elif ins.isLoadStore():
                        # Need to dispatch to load/store unit.
                        readyLSU.append(ins);
                        if len(readyLSU) >= maxLSU:
                            break
                    else:
                        readyALU.append(ins)
                        if len(readyALU) >= maxALU:
                            break

                    if ins.getOutReg() is not None:
                        self._reg.markScoreboard(ins.getOutReg(), True);
                else:
                    break

                # Regardless of data dependency, if this is a branch we don't want to pass any more ins (no speculative execution)
                if (ins.isBranch() and self._state_nxt[self.BRW_IND]) or ins.isHalt(): # Need to block on halt
                    # FOR NOW: Only let a single branch through.
                    # Mark that we are waiting for a conditional.
                    self._state_nxt[self.BRW_IND] = 1
                    break

        for ins in chain(readyALU, readyBRU, readyLSU):
            # Need to mark the pending write in the register scoreboard.
            print ins, 'OUT REG:', ins.getOutReg()
            if ins.getOutReg() is not None:
                self._reg.markScoreboard(ins.getOutReg(), True);

        # Need to shift down by the number of instructions we are passing out.
        count = len(readyALU) + len(readyBRU) + len(readyLSU)
        self._state_nxt[:self.RLD_IND-count] = self._state[count:self.RLD_IND]
        self._state_nxt[self.RLD_IND-count:self.RLD_IND] = [0] * (count)

        # Set the accept count
        self._state[self.EMP_IND] = count # JEEPERS CREEPERS
        
        print 'Ready:', readyALU, readyBRU, readyLSU
        if count < self._width:
            print 'DECODER IS BLOCKING/DELAYING'
        else:
            print 'DECODER OK'
        return (readyALU, readyBRU, readyLSU)

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
            return Instruction.NOP(word)
            #raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', word,  '{:032b}'.format(word))
