#!/usr/bin/env python

from Executor import Executor
from Writeback import Writeback

class BranchUnit(object):
    """ A specialised execution unit for performing branches, with it's own pipeline. """
    
    def __init__(self, myid, cpu, rob):
        """ ID is for debugging and display purposes. """
        self._id = myid;
        # Just reuse the general purpose executor
        self._executor = Executor(cpu) # Requires a reference to cpu, for branches
        self._writeback = Writeback(rob) # Need a writeback stage to pass into commit
        # Only an execute stage, branch instructions never write to registers or access mem

        # Easy iteration
        self._stages = (self._executor, self._writeback)

        # Pipeline information (currently for halt)
        self.pipelen = len(self._stages)
        self._stepcount = 0

    def execute(self, toExecute):
        """ Runs the current timestep. Should be issued an instruction. """
        # Update the step count (used to tell if pipe is clear of instructions).
        if toExecute.getOpc() == 'nop' or toExecute.getOpc() == 'dnop':
            self._stepcount += 1
        else:
            self._stepcount = 0
        
        # Pass to execute
        self._executor.updateInstruction(toExecute)

        # Execute Stage (this might undo all the previous steps, if we branch!)
        completedBr, stalled = self._executor.execute()

        self._writeback.updateInstruction(completedBr)

        self._writeback.writeback()

    def advstate(self):
        """ Updates the state of all components, ready for the next iteration. """
        for stg in self._stages:
            stg.advstate()

    def __str__(self):
        return '\n--Branch Unit--\n{1:s}'.format(self._id, '\n'.join((str(stg) for stg in self._stages)))

    # For list printing
    def __repr__(self):
        return str(self)
    
    def invalidateExecute(self):
        self._executor.invalidateInstruction()

    def hasInstructions(self):
        """ Tells if this unit has any instructions waiting to complete. (For halt) """
        return self._stepcount < self.pipelen
