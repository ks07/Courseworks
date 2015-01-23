
   Sample test.e file
   ----------------------
   This file provides basic test-specific constraints for the calc1 
   testbench.

<'

-- Testbench will make use of three different approaches to instruction generation:
-- 1) Exhaustive generation of command/din1/din2 cross, where data is restricted to power of 2 (first hot) groups.
--    This creates a rather large test suite, but gives us high coverage and hits some important corner cases.
-- 2) Biased Constrained Psuedo-Random Generation, which allows more variety in data, but falls foul of the
--    constraint solver taking the path of least resistance!
-- 3) Simplistic Constrained Psuedo-Random Generation of shift commands, to create a stress test. Shifts are
--    simple to generate, and should never produce error responses, thus are suitable to continually drive to
--    test priority logic.

-- The base instruction_s type will be used for exhaustive generation. This is because certain constraints
-- will cause the exhaustive generator to find contradictions and thus refuse to generate.
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

   // Add a log2 representation of each data in, so we can use the iterator approach to get full range coverage!
   din1_log : uint [0..32];
   din2_log : uint [0..32];

   keep soft din1 < ipow(2, din1_log);
   keep soft din1 >= ipow(2, din1_log - 1); // Use a soft constraint so we don't cause errors when log = 0!
   keep soft din2 < ipow(2, din2_log);
   keep soft din2 >= ipow(2, din2_log - 1);
};

extend cprg instruction_s {
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

}; // extend cprg instruction_s


extend driver_u {
   keep instructions_to_drive.is_all_iterations(.cmd_in, .din1_log, .din2_log);

   keep cprg_instructions_to_drive.size() == 500;

   keep parallel_drive_1.size() == 300;
   keep parallel_drive_2.size() == 300;
   keep parallel_drive_3.size() == 300;
   keep parallel_drive_4.size() == 300;
}; // extend driver_u


'>

