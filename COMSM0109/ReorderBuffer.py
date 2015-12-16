#!/usr/bin/env python

import collections # TODO: Should probably use deque instead of list

from Instruction import Instruction

class ReorderBuffer(object):
    """ A reorder buffer. Instructions stored here as soon as Completed instructions data added here in writeback, and committed seperately in order. """

    INS_ISSUED = 0
    INS_EXECUTING = 1
    INS_COMPLETED = 2
    
    def __init__(self, size, reg, mem):
        self._maxlen = size # Max number of entries in the reorder buffer
        self._reg = reg # Need to commit to registers
        self._mem = mem # Need to commit to memory
        # PUSH TO LEFT, POP ON RIGHT
        self._ins_buff = collections.deque() # Buffer of reserved instructions TODO: maxlen param
        self._ins_buff_nxt = collections.deque() # Next step

    def __str__(self):
        return 'Reorder Buffer: {0:s}'.format(str(self._ins_buff))

    def insIssued(self, ins):
        """ Adds a newly dispatched instruction to the end of the reorder buffer. """
        self._ins_buff_nxt.appendleft(ins)
        # Set the state of the instruction
        ins.rbstate = self.INS_ISSUED
        # Would usually be stored in a circular buffer, and would return index, but we can just use the object

    def insDispatched(self, ins):
        """ Update instruction state to show dispatched. """
        ins.rbstate = self.INS_EXECUTING
        
    def insWriteback(self, ins):
        """ Marks instruction as completed, waiting for commit. """
        ins.rbstate = self.INS_COMPLETED

    def commit(self):
        """ Check head of ROB and perform writes/remove if ready. """
        try:
            ins = self._ins_buff_nxt.pop()
        except IndexError:
            print 'Empty ROB'
            ins = Instruction.NOP()

        if ins.rbstate == self.INS_COMPLETED:
            print 'Committing', ins

            # Write to registers
            for ri, val in ins.getWBOutput():
                print 'Writing {0:d} in r{1:d}'.format(val, ri)
                self._reg[ri] = val
                self._scbdCheckSet(ri)

            # Write to memory
            memop = ins.getMemOperation()
            if memop:
                addr,write = memop
                if write is not None:
                    print 'Writing {0:d} in MEM[{1:d}]'.format(write, addr)
                    self._mem[addr] = write
        elif ins.asrc < 0:
            # We have stalled, should not add this back to ROB!
            print 'Ignoring', ins
        else:
            # Instruction not done, put back in ROB
            print 'Not ready to commit', ins
            self._ins_buff_nxt.append(ins)

    def _scbdCheckSet(self, ri):
        """ Checks the remainder of the ROB to see if scoreboard can be set. """
        # TODO: Might miss the latest instruction??? Searching in _nxt?
        for ins in self._ins_buff_nxt:
            oreg = ins.getOutReg()
            if oreg is not None and oreg == ri:
                print 'Pending write to scoreboard in ROB, not marking scoreboard.'
                return False # TODO: With speculative exec we will need to rectify this if the matching ins is speculative and later deleted.
        self._reg.markScoreboard(ri, False)
        return True

    def findLatestWrite(self, ri):
        """ Returns handle (would be ROB index) of the instruction we need result from, and if the ins is done. """
        for ins in self._ins_buff_nxt:
            oreg = ins.getOutReg()
            if oreg is not None and oreg == ri:
                return (ins, ins.rbstate == self.INS_COMPLETED)
        # Not sure if this should ever happen, but the result must be in the regfile.
        print 'WARNING (maybe): latest write guessed in regfile...', ri
        return None

    def decoderStalled(self, cancelled):
        """ The decoder stalled, so the decoded entries should be poisoned/removed/reused next iter. """
        for ins in reversed(cancelled):
            # Go by the assumption that these should match with the latest in buffer
            togo = self._ins_buff_nxt.popleft()
            assert togo is ins
    
    def advstate(self):
        self._ins_buff = collections.deque(self._ins_buff_nxt) # Need to copy the list TODO: Is a deep copy required?
        #return super(self.__class__, self).advstate();
