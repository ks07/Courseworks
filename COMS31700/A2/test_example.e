
   Sample test.e file
   ----------------------
   This file provides basic test-specific constraints for the calc1 
   testbench.

<'

extend instruction_s {
   keep port > 0;
   keep port < 5;
   keep cmd_in in [ADD,SUB,SHL,SHR,INV0,INV1,INV2,INV3,INV4,INV5,INV6,INV7,INV8,INV9,INVA];
   keep din1 < 0xFFFF_FFFF;
   keep din1 >= 0;
   keep din2 < 0xFFFF_FFFF;
   keep din2 >= 0;

   keep soft cmd_in == select {
     10: [INV0,INV1,INV2,INV3,INV4,INV5,INV6,INV7,INV8,INV9,INVA];
     90: [ADD,SUB,SHL,SHR]
   };

   // Bias shift distances to <34, to hit cases where we shouldn't just get 0s.
   keep soft cmd_in in [SHL,SHR] => din2 == select {
     33: [0..16];
     33: [17..33];
     33: [34..0xFFFF_FFFF];
   };

   // Bias sum results to < MAX_INT, to increase the number of resp 1 additions we expect.
   keep soft cmd_in == ADD => din1 + din2 == select {
     80: [0..0xFFFF_FFFF];
     20: [0x1_0000_0000..0x1_FFFF_FFFE];
   };

   // Bias subtraction results to > 0. Hard to do this in a simple constraint!
   when SUB'cmd_in instruction_s {
     sum_res : int(bits:33);
     keep sum_res == din1 - din2;
     keep soft sum_res == select {
       20: [-4294967296..-1];
       80: [0..0x0_FFFF_FFFF];
     };
     keep gen (sum_res) before (din1,din2); // Generate the target sum first!
   };

//   keep soft cmd_in == SUB => din1 < din2;

//   keep soft cmd_in == SUB => din1 - din2 == select {
//     999999999: [0x1_0000_0000..0xF_FFFF_FFFF];
//   };

   // Bias subtraction results to > 0. Doesn't work!
   //keep soft cmd_in == SUB => din1 - din2 == select {
   //  80: [0..0xFFFF_FFFF];
   //  10000000: [-1];
   //};
}; // extend instruction_s


extend driver_u {
   keep instructions_to_drive.size() == 1000;
   keep parallel_drive_1.size() == 300;
   keep parallel_drive_2.size() == 300;
   keep parallel_drive_3.size() == 300;
   keep parallel_drive_4.size() == 300;
}; // extend driver_u


'>

