
   Sample instruction.e file
   -------------------------
   This file provides the basic structure for the calc1 design instructions
   and also an example response checker for ADD instructions.

<'

type opcode_t : [ NOP, ADD, SUB, INV0, INV1, SHL, SHR, INV2, INV3, INV4, INV5, INV6, INV7, INV8, INV9, INVA ] (bits:4);


struct instruction_s {

   port   : uint (bits:3);
   %cmd_in : opcode_t;
   %din1   : uint (bits:32);
   %din2   : uint (bits:32);

   !resp   : uint (bits:2);
   !dout   : uint (bits:32);

   check_response(ins : instruction_s): bool is empty;

}; // struct instruction_s

extend instruction_s {

   // Add a field to get around the variance control field single value problem.
   is_inv : bool;
   keep is_inv == (cmd_in in [ INV0, INV1, INV2, INV3, INV4, INV5, INV6, INV7, INV8, INV9, INVA ]);

   // example check for correct addition
   when ADD'cmd_in instruction_s { 

     check_response(ins : instruction_s): bool is only {

       var expected_response : uint(bits:2);

       if ((ins.din1 + ins.din2) < ins.din1) || ((ins.din1 + ins.din2) < ins.din2) {
           expected_response = 02;
       } else {
           expected_response = 01;
       };

       result = (expected_response == 2);

       check that ins.resp == expected_response && ins.dout == (ins.din1 + ins.din2) else
       dut_error(appendf("[R==>Port %u invalid output.<==R]\n \
                          Instruction %s %u %u,\n \
                          response exp: %u rcv: %u \n \
                          expected %032.32b \t %u,\n \
                          received %032.32b \t %u.\n", 
                          ins.port, ins.cmd_in, ins.din1, ins.din2,
                          expected_response, ins.resp,
                          (ins.din1 + ins.din2),
                          (ins.din1 + ins.din2), 
                          ins.dout,ins.dout));
     }; // check_response

   }; // when

   when SUB'cmd_in instruction_s {

     check_response(ins : instruction_s): bool is only {
       var expected_response : uint(bits:2);

       // If only we could re-use the sum_res from the test generation...
       var my_sum_res : int(bits:33);
       my_sum_res = ins.din1 - ins.din2;

       var expected_data : uint(bits:32);

       if (my_sum_res < 0) {
           expected_response = 02;
	   expected_data = ins.din1 - ins.din2;
       } else {
           expected_response = 01;
	   expected_data = my_sum_res;
       };

       result = (expected_response == 2);

       check that ins.resp == expected_response && ins.dout == expected_data else
           dut_error(appendf("[R==>Port %u invalid output.<==R]\n \
                          Instruction %s %u %u,\n \
                          response exp: %u rcv: %u \n \
                          expected %032.32b \t %u,\n \
                          received %032.32b \t %u.\n",
                          ins.port, ins.cmd_in, ins.din1, ins.din2,
                          expected_response, ins.resp,
                          expected_data,
                          expected_data,
                          ins.dout,ins.dout));
       

     }; // check_response

   }; // when 

   when SHL'cmd_in instruction_s { 

     check_response(ins : instruction_s): bool is only {
       var exp_dout : uint;

       if ins.din2 > 31 {
         exp_dout = 0;
       } else {
         exp_dout = (ins.din1 << ins.din2);
       };

       result = FALSE;

       check that ins.resp == 01 && ins.dout == exp_dout else
       dut_error(appendf("[R==>Port %u invalid output.<==R]\n \
                          Instruction %s %u %u,\n \
                          response exp: %u rcv: %u \n \
                          expected %032.32b \t %u,\n \
                          received %032.32b \t %u.\n", 
                          ins.port, ins.cmd_in, ins.din1, ins.din2,
                          1, ins.resp,
                          exp_dout,exp_dout,
                          ins.dout,ins.dout));

     }; // check_response

   }; // when

   when SHR'cmd_in instruction_s { 

     check_response(ins : instruction_s): bool is only {
       var exp_dout : uint;

       if ins.din2 > 31 {
         exp_dout = 0;
       } else {
         exp_dout = (ins.din1 >> ins.din2);
       };

       result = FALSE;

       check that ins.resp == 01 && ins.dout == exp_dout else
       dut_error(appendf("[R==>Port %u invalid output.<==R]\n \
                          Instruction %s %u %u,\n \
                          response exp: %u rcv: %u \n \
                          expected %032.32b \t %u,\n \
                          received %032.32b \t %u.\n", 
                          ins.port, ins.cmd_in, ins.din1, ins.din2,
                          1, ins.resp,
                          exp_dout,exp_dout,
                          ins.dout,ins.dout));

     }; // check_response

   }; // when

   when is_inv instruction_s { 

     check_response(ins : instruction_s): bool is only {
       result = TRUE;
       check that ins.resp == 02 else
       dut_error(appendf("[R==>Port %u invalid output.<==R]\n \
                          Instruction %s %u %u,\n \
                          response exp: %u rcv: %u \n", 
                          ins.port, ins.cmd_in, ins.din1, ins.din2,
                          2, ins.resp));

     }; // check_response

   }; // when


}; // extend instruction_s

type instruction_kind: [standard, stress1, stress2, stress3, stress4];

extend instruction_s {
  // Add a field to indicate what mode we are in.
  !kind : instruction_kind;
  is_stress : bool;

  keep soft kind == standard;

  keep is_stress == (kind in [stress1, stress2, stress3, stress4]);

  keep gen (kind) before (is_stress);

  when is_stress {
    // For stress testing, restrict packets to non-error states.
    keep cmd_in in [SHL,SHR];
  }; // is_stress

  when stress1 {
    keep port == 1;
  };

  when stress2 {
    keep port == 2;
  };

  when stress3 {
    keep port == 3;
  };

  when stress4 {
    keep port == 4;
  };
};

'>

