#!/usr/bin/env python

from Executor import Executor
from MemoryAccess import MemoryAccess
from Writeback import Writeback

class ExecuteUnit(object):
    """ A general purpose execution unit, with it's own pipeline. """
    
    def __init__(self, myid, mem, reg, cpu):
        """ ID is for debugging and display purposes. """
        self._id = myid;
        self._executor = Executor(cpu) # Requires a reference to cpu, for branches
        self._memaccess = MemoryAccess(mem, self._executor) # Requires a ref to executor, for forwarding
        self._writeback = Writeback(reg)

        # Easy iteration
        self._stages = (self._executor, self._memaccess, self._writeback)

    def execute(self, toExecute):
        """ Runs the current timestep. Should be issued an instruction. """
        # Pass to execute
        self._executor.updateInstruction(toExecute)

        # Execute Stage (this might undo all the previous steps, if we branch!)
        toMacc = self._executor.execute()
        # Handles printing

        # Pass to memory access
        self._memaccess.updateInstruction(toMacc)

        # Memory access stage
        toWriteback = self._memaccess.memaccess()

        # Pass to writeback
        self._writeback.updateInstruction(toWriteback)

        # Writeback stage
        self._writeback.writeback()

    def advstate(self):
        """ Updates the state of all components, ready for the next iteration. """
        for stg in self._stages:
            stg.advstate()

    def __str__(self):
        return '\n--Execution Unit {0:d}--\n{1:s}'.format(self._id, '\n'.join((str(stg) for stg in self._stages)))

    def invalidateExecute(self):
        self._executor.invalidateInstruction()
