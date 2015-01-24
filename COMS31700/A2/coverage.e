
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
   };

   cover instruction_complete is also {
      // Get power-of-two coverage for both operands. This helps us ensure we have generated a nice spread of data inputs.
      // This should flag up interesting cases being missed such as data of 0, or small/large data.
      // Unfortunately, hitting a high coverage metric here will be difficult.
      item din1 using first_high_bit;
      item din2 using first_high_bit;
      cross cmd_in, din1, din2 using ignore = (cmd_in in [ INV0, INV1, INV2, INV3, INV4, INV5, INV6, INV7, INV8, INV9, INVA ]);
//    item din1 using ranges={range([0x0000_0000..0x00FF_FFFF], "low quarter", UNDEF, 256);
//                            range([0x0F00_0000..0x0FFF_FFFF], "mid-low quarter", UNDEF, 256);
//                            range([0xF000_0000..0xF0FF_FFFF], "mid-high quarter", UNDEF, 256);
//                            range([0xFF00_0000..0xFFFF_FFFF], "high quarter", UNDEF, 256);
//    };
//    item din2 using
   };

}; // extend instruction_s

extend driver_u {

   collect_response(ins : instruction_s) @clk is also {

      emit ins.instruction_complete;

   };

}; // extend driver_u

'>

