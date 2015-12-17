#!/usr/bin/env python

import numpy as np
from StatefulComponent import StatefulComponent
from Instruction import Instruction
from InstructionFormats import FORMATS

class DecoderSimple(StatefulComponent):
    """ A decode unit. State is the current instruction in this stage, and an indicator for load stalling. """

    NO_LD = 64
    
    def __init__(self, regfile, width, rob):
        # Width gives the number of instructions that are held and decoded.
        self.RLD_IND = width
        self.BRW_IND = width + 1 # Index of branch wait indicator, if set we should issue nothing until branch is resolved.
        self._state = np.zeros(width + 2, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)
        self._srcas = np.ones(width, dtype=np.int64) * -1
        self._srcas_nxt = np.ones(width, dtype=np.int64) * -1
        # Decode stage reads from register file.
        self._reg = regfile
        self._rob = rob
        self._width = width

        self.BRBLOCK = False
        
    def __str__(self):
        #return 'Decoding now: {0:08x} => {1:s}'.format(self._state[0], str(self._decode(self._state[0])))
        return 'Decoder buffer: ' + str(self._state[:self.RLD_IND]) + ' @ ' + str(self._srcas)

    def advstate(self):
        # TODO: should call super
        np.copyto(self._state, self._state_nxt, casting='no')
        np.copyto(self._srcas, self._srcas_nxt, casting='no')
        # Need to handle dependency checking

    def stall(self):
        """ Stall this stage this timestep """
        # Next step should use the same input.
        np.copyto(self._state_nxt, self._state, casting='no')
        np.copyto(self._srcas_nxt, self._srcas, casting='no')

    def queueInstructions(self, toDecodeList, addrs):
        # Put at end of waiting list in state. TODO: Probably unnecessary now?
        self._state_nxt[self.RLD_IND-len(toDecodeList):self.RLD_IND] = toDecodeList
        self._srcas_nxt[self.RLD_IND-len(toDecodeList):self.RLD_IND] = addrs
        print self._state_nxt
        print self._srcas_nxt

    def pipelineClear(self):
        """ Called when the stage needs clearing due to a branch misprediction. """
        self._state_nxt[:self._width] = 0 # Clear the instruction buffers
        self._state_nxt[self.RLD_IND] = self.NO_LD # Don't need to bubble for load
        self._srcas_nxt = np.zeros_like(self._srcas_nxt)

    def branchResolved(self):
        """ Called when a branch has been resolved (made it out of execute). Unblocks issue. """
        self._state_nxt[self.BRW_IND] = 0

    def issue(self):
        """ Decodes current inputs, issues instructions up to width. Issue bound fetch, non-blocking! """
        ready = []
        blocked = None
        if self.BRBLOCK and self._state[self.BRW_IND]:
            # Waiting for a branch, don't accept anything.
            print 'OLEOLOLEOLEOELEOELOLEOELEO BRANCH WAITING'
            blocked = 2
        else:
            for b,a in zip(self._state[:self._width],self._srcas[:self._width]):
                ins = self._decode(b,a)
                print ins
                ready.append(ins)
                self._rob.insIssued(ins)
                self._rob.tagDependentWrite(ins) # Tag the dependent instructions for later fetch when ready
                # Mark scoreboard
                if ins.getOutReg() is not None:
                    print ' MARKING SCOREBOARD FOR',ins.getOutReg(),ins
                    self._reg.markScoreboard(ins.getOutReg(), True)
                if self.BRBLOCK and ins.isBranch():
                    # Block on branches for now
                    self._state_nxt[self.BRW_IND] = 1
                    blocked = self._width - len(ready)
                    break
        return ready, blocked
        
    def _decode(self, word, asrc = -1):
        """ Decodes a given word; return an Instruction object represented by word. """
        group = word >> 26 # All instructions start with a possibly unique 6 bit ID
        diff = word & 0x1F # Where ins not identified uniquely by group, the 5 LSBs should differentiate

        possible = [(opc, frmt) for opc, frmt in FORMATS.iteritems() if frmt[0] == group]

        if not possible:
            # If invalid instruction, either the program is going to branch before this
            # is executed, the program has a bug, or the sim has a bug!
            # The first possibility is not an error, so replace instruction with something we can pass!
            return Instruction.NOP(word, asrc)
        elif len(possible) == 1:
            opc, frmt = possible[0]
            if diff != frmt[-1] and not isinstance(frmt[-1], basestring):
                return Instruction.NOP(word, asrc)
            # The Instruction constructor deals with splitting args.
            return Instruction(asrc, opc, frmt, word, self._reg)
        else:
            for opc, frmt in possible:
                if frmt[-1] == diff:
                    return Instruction(asrc, opc, frmt, word, self._reg)
            return Instruction.NOP(word, asrc)
            #raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', word,  '{:032b}'.format(word))
