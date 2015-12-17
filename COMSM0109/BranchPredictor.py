#!/usr/bin/env python

class BranchPredictor(object):
    """ A static branch predictor. """

    def predict(self, ins):
        """ Returns true if we predict the branch will be taken. """
        return True
        pc = ins.asrc # TODO: PC might be weird, so just check the instruction location
        if ins.getOpc() == 'br':
            # Unconditional, always taken
            return True
        else:
            dest = ins.getOpr()[-1]
            return dest < pc
