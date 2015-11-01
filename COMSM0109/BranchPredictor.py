#!/usr/bin/env python

from StatefulComponent import StatefulComponent

class BranchPredictor(StatefulComponent):
    """ A static branch predictor. """

    def predict(self, pc, ins):
        """ Returns true if we predict the branch will be taken. """
        if ins.getOpc() == 'br':
            # Unconditional, always taken
            return True
        else:
            dest = ins.getOpr()[-1]
            return dest < pc
