#!/usr/bin/env python

class Instruction(object):
    """ An instruction. """

    @staticmethod
    def _decf2strf(frmt):
        """ Converts a decode format tuple to a python str.format compatible format string. Static method. """
        strf = []
        for a in frmt[1:-1]:
            if a == 'r':
                strf.append('r{:d}')
            else:
                strf.append('{:d}')
        # Need to cover end = imm
        if frmt[-1] == 'i':
            strf.append('{:d}')
        return ("{} " + ",".join(strf)).rstrip()

    @staticmethod
    def NOP(debug = False):
        """ Gets a NOP instruction, as a placeholder. If debug is set, the instruction should never be executed, and will throw an error if attempted. """
        if debug:
            return Instruction('dnop', (0,1), debug, None) # Abuse the word field to hold the potentially invalid inst
        else:
            return Instruction('nop', (0,0), 0, None)

    def __init__(self, opcode, frmt, word, regfile, predicted=False):
        self._opcode = opcode
        self._frmt_str = Instruction._decf2strf(frmt) # If we subclass this becomes unnecessary?
        # Store reg => val index mapping, for register bypassing.
        self._rvmap = {}
        # Note the similarity to gen_ins in assember!
        operands = []
        values = [] # Decode stage should read from regs
        shift = 26
        for arg in frmt[1:-1]:
            if arg == 'r':
                shift -= 5
                mask = 0x1F
                ri = (word >> shift) & mask
                self._rvmap[ri] = len(values)
                values.append(regfile[ri])
            elif arg == 'i':
                shift -= 16
                mask = 0xFFFF
                values.append((word >> shift) & mask)
            else:
                raise ValueError("Bad argument type when trying to get operand from word.", arg, opcode, frmt, word)
            operands.append((word >> shift) & mask)
        # Need to cover the case where the end of the instruction is an immediate
        if frmt[-1] == 'i':
            operands.append(word & 0xFFFF)
            values.append(word & 0xFFFF)
        self._operands = tuple(operands)
        self._values = values # TODO?: some of these values will not be used (will grab output reg!)
        # Store the source word, for debug.
        self._word = word;
        # Store if the branch predictor has decided to take this
        self.predicted = predicted
        # Store the output, for the writeback stage.
        self._writeback = []
        # Store memory op, for mem access stage.
        self._memOpp = None
        print 'Read values',values

    def getOpc(self):
        return self._opcode

    def getOpr(self):
        return self._operands

    def getVal(self):
        return self._values

    def getWord(self):
        """ Get word, for debugging! """
        return self._word

    def getRegValMap(self):
        return self._rvmap

    def setMemOperation(self, addr, write=None):
        # TODO: Can we stop doing this?
        self._memOpp = (addr, write)

    def getMemOperation(self):
        return self._memOpp

    def setWBOutput(self, reg, val):
        """ Sets the register/value for writeback output. """
        # Put in a list, in case we add any instructions with multiple outputs
        self._writeback = [(reg, val)]

    def getWBOutput(self):
        """ Gets the register/value for writeback output. """
        return tuple(self._writeback)

    def __str__(self):
        # This is the implode_ins function in the assembler!
        return self._frmt_str.format(self._opcode, *self._operands)
