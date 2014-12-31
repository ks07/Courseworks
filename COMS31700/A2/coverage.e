
   Sample coverage.e file
   ----------------------
   This file provides a basic example of coverage collection for the calc1 
   testbench.

<'

extend instruction_s {

   event instruction_complete;

   cover instruction_complete is {
      item port using illegal=port>4||port<1;
      item cmd_in using illegal=cmd_in==NOP;
      item resp using illegal=resp<1||resp>2;
      cross port, cmd_in, resp;
   }

}; // extend instruction_s

extend driver_u {

   collect_response(ins : instruction_s) @clk is also {

      emit ins.instruction_complete;

   };

}; // extend driver_u

'>

