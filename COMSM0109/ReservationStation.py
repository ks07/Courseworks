#!/usr/bin/env python

#import collections # TODO: Should probably use deque instead of list

from StatefulComponent import StatefulComponent
import numpy as np

class ReservationStation(StatefulComponent):
    """ A reservation station. Instructions are dispatched from here to EUs. For a single type of EU. """

    RBD1_IND = 32
    RBD2_IND = 33
    RBD3_IND = 34
    BRW_IND = 35
    
    def __init__(self, myid, maxDisp, reg, buffLen, rob):
        self._id = str(myid) # Some ID for display purposes
        self._max_disp = maxDisp # The max number of instructions to dispatch per cycle
        self._ins_buff = [] # Instruction buffer
        self._ins_buff_nxt = []
        self._state = np.zeros(36, dtype=np.uint32) # For holding bypassed values (TODO: no shifts like scalar?)
        self._state_nxt = np.zeros_like(self._state)
        #self._writers = [] # Holds current registers waiting for write
        self._branched_now = False # Marks if a branch has been dispatched yet this time step.
#        self._writing_now = set()
        # Need a handle to register file
        self._reg = reg
        # Need handle to reorder buffer
        self._rob = rob
        # Store max length of buffer.
        self._buffLen = buffLen
        self._prevStall = False # Marks if the previous step was a s

    def __str__(self):
        return 'Reservation Station {0:s}: {1:s}'.format(self._id, str(self._ins_buff))

    def queueInstructions(self, ins):
        """ Puts instructions on the stage input. Returns True if we should stall previous. """
        if len(self._ins_buff_nxt) + len(ins) <= self._buffLen:
            self._ins_buff_nxt.extend(ins)
            print 'extended',self._ins_buff_nxt
            return False
        else:
            print 'RS buffer full'
            return True

    def bypassBack(self, age, reg, val):
        """ Inserts a value back into the bypass registers, from a later stage. """
        # # TODO: We might only need support for age == 2, so forget generalising for now
        # if age != 2:
        #     raise ValueError('Unimplemented bypassBack age!', age);

        # if not self._state_nxt[self.RBD1_IND] & reg:
        #     self._state_nxt[reg] = val
        # # Need to pass this back 2 steps
        # self._state_nxt[self.RBD2_IND] |= (1 << reg)
        return # Surpassed by rob, we hope

    def pipelineClear(self):
        """ Mispredicted branch! Clear the pipeline. """
        self._ins_buff_nxt = []
        
    def branchResolved(self):
        """ Called when a branch has been resolved (made it out of execute). Unblocks issue. """
        print 'WOAH UNBLOCKED 80085'
        self._state_nxt[self.BRW_IND] = 0

    def _insReady(self,ins):
        """ DEBUG WRAPPER, CAUSE I SUCK """
        print 'TESTING READY',ins
        ret = self._insReady2(ins)
        if ret and ins.isBranch():
            self._branched_now = True
            self._state_nxt[self.BRW_IND] = 1
        return ret
        
    def _insReady2(self, ins):
        """ Decides if an instruction is ready to be dispatched. """
        # We want to stall after a branch.
#        if self._branched_now or self._state[self.BRW_IND] == 1:
#            print 'DONT WANT NONE',self._branched_now,self._state[self.BRW_IND]
#            return False
        self._rob.fillInstruction(ins)
        return not ins.getInvRegs()
        
    def dispatch(self):
        # Set the next state
        self._ins_buff_nxt = list(self._ins_buff)
        self._branched_now = False
        writing_now = set()

        toremove = []
        togo = []
        i = 0

        while len(togo) < self._max_disp and i < len(self._ins_buff):
            # In order for now
            ins = self._ins_buff[i]
            oreg = ins.getOutReg()

            if oreg not in writing_now and self._insReady(ins):
                # Can dispatch
                togo.append(ins)
                toremove.append(i) # Remove from choices for next time.

                # Update state in ROB
                self._rob.insDispatched(ins)

                # Don't dispatch two writes to the same register at once.
                if ins.getOutReg() is not None:
                    writing_now.add(ins.getOutReg())
            else:
                break
            i += 1

#            if (ins.isBranch() and self._state_nxt[self.BRW_IND]) or ins.isHalt(): # Need to block on halt
#                # FOR NOW: Only let a single branch through.
#                # Mark that we are waiting for a conditional.
#                self._state_nxt[self.BRW_IND] = 1
#                break

        print 'rem', toremove, self._ins_buff, self._ins_buff_nxt
        for j in sorted(toremove, reverse=True):
            self._ins_buff_nxt.pop(j)

        print 'Dispatching', togo, self._ins_buff, self._ins_buff_nxt
        return togo

    def advstate(self):
        self._ins_buff = list(self._ins_buff_nxt) # Need to copy the list TODO: Is a deep copy required?
        return super(self.__class__, self).advstate();
