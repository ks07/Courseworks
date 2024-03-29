#!/usr/bin/env python

import collections # TODO: Should probably use deque instead of list

from Instruction import Instruction

class ReorderBuffer(object):
    """ A reorder buffer. Instructions stored here as soon as Completed instructions data added here in writeback, and committed seperately in order. """

    INS_ISSUED = 0
    INS_EXECUTING = 1
    INS_COMPLETED = 2
    
    def __init__(self, size, reg, mem, cpu):
        self._maxlen = size # Max number of entries in the reorder buffer
        self._reg = reg # Need to commit to registers
        self._mem = mem # Need to commit to memory
        # PUSH TO LEFT, POP ON RIGHT
        self._ins_buff = collections.deque() # Buffer of reserved instructions TODO: maxlen param
        self._ins_buff_nxt = collections.deque() # Next step
        self._cpu = cpu

        # Debug/Output Variables
        self.INSTRUCTIONS_COMMITTED = 0 # Normally completed instruction count
        self.INSTRUCTIONS_DISCARDED = 0 # Wrongly speculatively executed instruction count
        self.BRANCH_MISPREDICTIONS = 0 # Number of branch mispredictions
        self.TOTAL_BRANCHES = 0 # Total number of branch instructions executed

    def __str__(self):
        return 'Reorder Buffer: {0:s}'.format(str(self._ins_buff))

    def insIssued(self, ins):
        """ Adds a newly dispatched instruction to the end of the reorder buffer. """
        prev = self._ins_buff_nxt[0] if len(self._ins_buff_nxt) > 0 else Instruction.NOP()
        # Would usually be stored in a circular buffer, and would return index, but we can just use the object
        self._ins_buff_nxt.appendleft(ins)
        # Set the state of the instruction
        ins.rbstate = self.INS_ISSUED

    def insDispatched(self, ins):
        """ Update instruction state to show dispatched. """
        ins.rbstate = self.INS_EXECUTING
        
    def insWriteback(self, ins):
        """ Marks instruction as completed, waiting for commit. """
        print 'MARKING COMPLETE',ins
        ins.rbstate = self.INS_COMPLETED

    def commit(self):
        """ Check head of ROB and perform writes/remove if ready. """
        try:
            ins = self._ins_buff_nxt.pop()
        except IndexError:
            print 'Empty ROB'
            ins = None

        while ins is not None and (ins.rbstate == self.INS_COMPLETED or ins.isNOP()):
            if ins.robpoisoned:
                print 'Poisoned, deleting', ins
                if ins.isBranch():
                    self._cpu._rob_branch_poisoned(ins)
                # Record this discard
                self.INSTRUCTIONS_DISCARDED += 1
            else:
                print 'Committing', ins

                self.INSTRUCTIONS_COMMITTED += 1

                if ins.isHalt():
                    self._cpu.halt()

                if ins.isBranch():
                    self.TOTAL_BRANCHES += 1
                    mispredicted = self._cpu._rob_branch(ins)
                    if mispredicted:
                        self.BRANCH_MISPREDICTIONS += 1
                        discard = []
                        # Mark all later instructions.
                        for ilater in self._ins_buff_nxt:
                            print 'Poisoning',ilater,'due to',ins
                            ilater.robpoisoned = True
                            if ilater.rbstate == self.INS_ISSUED:
                                # Can cut these out now
                                discard.append(ilater)
                            else:
                                # This ins is executing (or done!), can mark reg as valid
                                ri = ilater.getOutReg()
                                if ri is not None:
                                    #pass
                                    self._reg.markScoreboard(ri, False)
                        for ilater in discard:
                            print 'Discarding',ilater,'due to',ins
                            self._ins_buff_nxt.remove(ilater)

                # Write to registers
                for ri, val in ins.getWBOutput():
                    if val is None:
                        raise ValueError('Bad mem value - should have been poisoned?', ins)
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

            try:
                ins = self._ins_buff_nxt.pop()
            except IndexError:
                print 'Empty ROB'
                ins = None
                    
        # elif ins.asrc < 0:
        #     # We have stalled, should not add this back to ROB!
        #     print 'Ignoring', ins
        # else:
        if ins is not None and ins.asrc >= 0:
            # Instruction not done, put back in ROB
            print 'Not ready to commit', ins
            self._ins_buff_nxt.append(ins)

    def _scbdCheckSet(self, ri):
        """ Checks the remainder of the ROB to see if scoreboard can be set. """
        # TODO: Might miss the latest instruction??? Searching in _nxt?
        for ins in self._ins_buff_nxt:
            oreg = ins.getOutReg()
            if oreg is not None and oreg == ri:
                print 'Pending write to scoreboard in ROB, not marking scoreboard. ERMAHWUT', ri, ins
                return False # TODO: With speculative exec we will need to rectify this if the matching ins is speculative and later deleted.
        self._reg.markScoreboard(ri, False)
        return True

    def tagDependentWrite(self, new_ins):
        """ Puts handle for dependent write into the robvmap for the instruction. Might actually work. """
        earlier = False
        irs = new_ins.getInvRegs().copy()
        for ins in self._ins_buff_nxt:
            if earlier:
                oreg = ins.getOutReg()
                if oreg is not None and oreg in irs:
                    new_ins.rrobmap[oreg] = ins # Mark that new_ins should get value for oreg from ins
                    irs.remove(oreg) # Dont keep looking for this inv reg
            elif ins is new_ins:
                # Can only be dependent on an earlier instruction!
                earlier = True
        # Not sure if this should ever happen, but the result must be in the regfile.
        print 'irstag',irs
#        assert len(irs) == 0
        for ri in irs:
            print 'WARNING (maybe): latest write guessed in regfile...',new_ins
            new_ins.rrobmap[ri] = None
        #return None

    def fillInstruction(self, ins):
        """ Fills as many invalid values as possible from completed and queued instructions. """
        print 'filling',ins
        for ri,vi in ins.getRegValMap().iteritems(): # TODO: Support for multiple value targets per reg
            if ri in ins.getInvRegs():
                # Loop through invalid regs, let us remove them.
                if ri in ins.rrobmap and ins.rrobmap[ri] is not None:
                    depIns = ins.rrobmap[ri]
                    if depIns.rbstate == self.INS_COMPLETED:
                        ins.getInvRegs().remove(ri)
                        ins._values[vi] = depIns.getOutVal()
                    print 'checking r',ri,'depIns',depIns,'state',depIns.rbstate,self.INS_COMPLETED
                elif ri in ins.rrobmap and ins.rrobmap[ri] is None:
                    print ' THIS IS BAD, BUT DOES IT WORK?',ins,ri
                    ins._values[vi] = self._reg[ri]
                    ins.getInvRegs().remove(ri)
                else:
                    print ' THIS IS BAD, BUT DOES IT WORK?',ins,ri
                    ins._values[vi] = self._reg[ri]

    # Probably useless
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
        oregs = set()
        for ins in reversed(cancelled):
            # Go by the assumption that these should match with the latest in buffer
            togo = self._ins_buff_nxt.popleft()
            assert togo is ins
            if togo.getOutReg() is not None:
                oregs.add(togo.getOutReg())

        for ri in oregs:
            # Need to mark scoreboard as valid if the bit was flipped by the stalled instructions
            self._scbdCheckSet(ri)

    def advstate(self):
        self._ins_buff = collections.deque(self._ins_buff_nxt) # Need to copy the list TODO: Is a deep copy required?
        #return super(self.__class__, self).advstate();
