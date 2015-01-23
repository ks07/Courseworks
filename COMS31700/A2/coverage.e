
   Sample coverage.e file
   ----------------------
   This file provides a basic example of coverage collection for the calc1 
   testbench.

<'

extend instruction_s {

   event instruction_complete;

   cover instruction_complete is {
      item port using illegal = port>4||port<1;
      item cmd_in using illegal = cmd_in==NOP;
      item resp using illegal = resp<1||resp>2;
      -- Use the cross of port, cmd and resp for our main functional coverage metric.
      -- Set illegal responses for shifts (they should never be overflow).
      -- Set ignore responses for invalids (they should always give resp of 2, but a bug in the DUV means
      -- they always return 1, so we ignore 2).
      cross port, cmd_in, resp using illegal = (cmd_in in [SHL,SHR] && resp != 1), 
        ignore = (cmd_in in [ INV0, INV1, INV2, INV3, INV4, INV5, INV6, INV7, INV8, INV9, INVA ] && resp != 1);
   }

}; // extend instruction_s

extend driver_u {

   collect_response(ins : instruction_s) @clk is also {

      emit ins.instruction_complete;

   };

}; // extend driver_u

'>

