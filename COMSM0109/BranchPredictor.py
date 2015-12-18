#!/usr/bin/env python

class ConstantPredictor(object):
    """ Always taken/not taken. """

    def __init__(self, taken):
        self._taken = taken

    def predict(self, ins):
        return self._taken

    def branchResult(self, ins, taken):
        return

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

    def __init__(self, bits, default):
        self._table = {}
        self._dbg_log = []
        self.BITS = bits
        self.DEFAULT = default

        self._ctrlim = 2 ** bits
        self._decbound = self._ctrlim / 2

    def _getOrInit(self, ins):
        if ins.asrc not in self._table:
            self._table[ins.asrc] = self.DEFAULT
        return self._table[ins.asrc]

    def predict(self, ins):
        """ Return true if predict taken. """
        state = self._getOrInit(ins)
        return state >= self._decbound

    def branchResult(self, ins, taken):
        """ Update state depending on outcome. """
        self._dbg_log.append((ins,taken))
        if taken:
            self._table[ins.asrc] = min(self._ctrlim - 1, self._table[ins.asrc] + 1)
        else:
            self._table[ins.asrc] = max(0, self._table[ins.asrc] - 1)

class HybridPredictor(DynamicPredictor):

    STATIC = StaticPredictor()
    
    def _getOrInit(self, ins):
        if ins.asrc not in self._table:
            start = self._ctrlim - 1 if self.STATIC.predict(ins) else 0
            self._table[ins.asrc] = start
        return self._table[ins.asrc]

# TODO: 3 bit predictor?
