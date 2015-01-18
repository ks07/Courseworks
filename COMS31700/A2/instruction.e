
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

       if ((ins.din1 - ins.din2) > ins.din1) || ((ins.din1 - ins.din2) > ins.din2) {
           expected_response = 02;
       } else {
           expected_response = 01;
       };

       result = (expected_response == 2);

       check that ins.resp == expected_response && ins.dout == (ins.din1 - ins.din2) else
           dut_error(appendf("[R==>Port %u invalid output.<==R]\n \
                          Instruction %s %u %u,\n \
                          response exp: %u rcv: %u \n \
                          expected %032.32b \t %u,\n \
                          received %032.32b \t %u.\n",
                          ins.port, ins.cmd_in, ins.din1, ins.din2,
                          expected_response, ins.resp,
                          (ins.din1 - ins.din2),
                          (ins.din1 - ins.din2),
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


'>

