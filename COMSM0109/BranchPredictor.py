#!/usr/bin/env python

class StaticPredictor(object):
    """ A static branch predictor. """

    def predict(self, ins):
        """ Returns true if we predict the branch will be taken. """
        pc = ins.asrc # TODO: PC might be weird, so just check the instruction location
        if ins.getOpc() == 'br':
            # Unconditional, always taken
            return True
        else:
            dest = ins.getOpr()[-1]
            return dest < pc

    def branchResult(self, ins, taken):
        return

class DynamicPredictor(object):
    """ A dynamic branch predictor, with a 1-bit counter per branch. """

    def __init__(self):
        self._table = {}
        self._dbg_log = []

    def _getOrInit(self, ins):
        if ins.asrc not in self._table:
            self._table[ins.asrc] = 0
        return self._table[ins.asrc]

    def predict(self, ins):
        """ Return true if predict taken. """
        state = self._getOrInit(ins)
        return state == 1

    def branchResult(self, ins, taken):
        """ Update state depending on outcome. """
        self._dbg_log.append((ins,taken))
        self._table[ins.asrc] = 1 if taken else 0
