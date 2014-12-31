
   Sample test.e file
   ----------------------
   This file provides basic test-specific constraints for the calc1 
   testbench.

<'

extend instruction_s {
   keep cmd_in in [ADD,SUB,SHL,SHR];
//   keep cmd_in in [ADD,SUB,SHL,SHR,INV,INV1];
//   keep soft cmd_in == select {10: [INV,INV1]; 90: [ADD,SUB,SHL,SHR]};
   keep din1 < 0xFFFF_FFFF;
   keep din1 >= 0;
//   keep soft din1 == select {25: [3..4]; 50: 2};
   keep din2 < 0xFFFF_FFFF;
   keep din2 >= 0;
   keep port > 0;
   keep port < 5;
}; // extend instruction_s


extend driver_u {
   keep instructions_to_drive.size() == 120;
}; // extend driver_u


'>

