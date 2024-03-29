#!/usr/bin/env python

#import collections # TODO: Should probably use deque instead of list

from StatefulComponent import StatefulComponent
import numpy as np

class ReservationStation(StatefulComponent):
    """ A reservation station. Instructions are dispatched from here to EUs. For a single type of EU. """

    RBD1_IND = 32
    RBD2_IND = 33
    RBD3_IND = 34
    
    def __init__(self, myid, reg, buffLen, rob):
        self._id = str(myid) # Some ID for display purposes
        self._ins_buff = [] # Instruction buffer
        self._ins_buff_nxt = []
        self._state = np.zeros(35, dtype=np.uint32) # For holding bypassed values (TODO: no shifts like scalar?)
        self._state_nxt = np.zeros_like(self._state)
        self._branched_now = False # Marks if a branch has been dispatched yet this time step.
        self._multicycles = []
        self._multicycles_nxt = []
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
            return False
        else:
            print 'RS buffer full'
            return True

    def pipelineClear(self):
        """ Mispredicted branch! Clear the pipeline. """
        self._ins_buff_nxt = []

    def stallingEU(self, lins):
        """ Stalled EU, putting inss back into the buffer. """
        self._ins_buff_nxt = lins + self._ins_buff_nxt
        
    def _insReady(self,ins):
        """ DEBUG WRAPPER, CAUSE I SUCK """
        ret = self._insReady2(ins)
        return ret
        
    def _insReady2(self, ins):
        """ Decides if an instruction is ready to be dispatched. """
        # We want to stall after a branch.
        if self._branched_now:
            print 'DONT WANT NONE',self._branched_now
            return False
        self._rob.fillInstruction(ins)
        return not ins.getInvRegs()
    
    def dispatch(self):
        # Set the next state
        self._ins_buff_nxt = list(self._ins_buff)
        self._branched_now = False
        writing_now = set()

        togo_ALU = []
        max_disp_ALU = 2
        togo_BRU = []
        max_disp_BRU = 1
        togo_LSU = []
        max_disp_LSU = 1
        
        self._multicycles_nxt = []
        for mins in self._multicycles:
            if mins.cycleCnt(True) and not mins.robpoisoned:
                self._multicycles_nxt.append(mins)
                max_disp_ALU -= 1 # Reduce/stall dispatch
            else:
                # Can dispatch again!
                pass
        print 'NOW ACCEPTING FOR RS ALU',max_disp_ALU

        toremove = []
        i = 0

        while (len(togo_ALU) < max_disp_ALU or len(togo_BRU) < max_disp_BRU or len(togo_LSU) < max_disp_LSU) and i < len(self._ins_buff):
            # In order for now
            ins = self._ins_buff[i]
            oreg = ins.getOutReg()

            print 'CHECKING DISP', ins, max_disp_LSU, togo_LSU
            self._rob.tagDependentWrite(ins)

            #if oreg not in writing_now and self._insReady(ins):
            if self._insReady(ins):
                print 'READY FOR DISP', ins
                # Can dispatch, if there's room!
                if ins.isBranch() or ins.isHalt():
                    if len(togo_BRU) < max_disp_BRU:
                        togo_BRU.append(ins)
                    else:
                        break
                elif ins.isLoadStore():
                    if len(togo_LSU) < max_disp_LSU:
                        print 'APPEND DISP'
                        togo_LSU.append(ins)
                    else:
                        break
                else:
                    if len(togo_ALU) < max_disp_ALU:
                        togo_ALU.append(ins)
                        if ins.cycleLen() > 1:
                            self._multicycles_nxt.append(ins)
                    else:
                        break

                toremove.append(i) # Remove from choices for next time.

                # Update state in ROB
                self._rob.insDispatched(ins)

                # Don't dispatch two writes to the same register at once.
                if ins.getOutReg() is not None:
                    writing_now.add(ins.getOutReg())
                    
                if ins.isBranch():
                    self._branched_now = True # Don't dispatch multiple branches at once... is this necessary?
            i += 1


        for j in sorted(toremove, reverse=True):
            self._ins_buff_nxt.pop(j)

        return togo_ALU, togo_BRU, togo_LSU

    def advstate(self):
        self._ins_buff = list(self._ins_buff_nxt) # Need to copy the list TODO: Is a deep copy required?
        self._multicycles = list(self._multicycles_nxt)
        return super(self.__class__, self).advstate();
