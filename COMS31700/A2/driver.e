
   Sample driver.e file
   --------------------
   This file provides the basic structure for the calc1 testbench 
   driver. 

   The driver interacts directly with the DUV by driving test data into
   the DUV and collecting the response from the DUV. It also invokes the
   instruction specific response checker. 

<'

unit driver_u {

   clk_p : inout simple_port of bit is instance; // can be driven or read by sn
   keep clk_p.hdl_path() == "~/calc1_sn/c_clk";

   reset_p : out simple_port of uint(bits:7) is instance; // driven by sn
   keep reset_p.hdl_path() == "~/calc1_sn/reset";

   req1_cmd_in_p : out simple_port of uint(bits:4) is instance; // driven by sn
   keep req1_cmd_in_p.hdl_path() == "~/calc1_sn/req1_cmd_in";

   req1_data_in_p : out simple_port of uint(bits:32) is instance; // driven by sn
   keep req1_data_in_p.hdl_path() == "~/calc1_sn/req1_data_in";

   out_resp1_p : in simple_port of uint(bits:2) is instance; // read by sn
   keep out_resp1_p.hdl_path() == "~/calc1_sn/out_resp1";

   out_data1_p : in simple_port of uint(bits:32) is instance; // read by sn
   keep out_data1_p.hdl_path() == "~/calc1_sn/out_data1";

   req2_cmd_in_p : out simple_port of uint(bits:4) is instance; // driven by sn
   keep req2_cmd_in_p.hdl_path() == "~/calc1_sn/req2_cmd_in";

   req2_data_in_p : out simple_port of uint(bits:32) is instance; // driven by sn
   keep req2_data_in_p.hdl_path() == "~/calc1_sn/req2_data_in";

   out_resp2_p : in simple_port of uint(bits:2) is instance; // read by sn
   keep out_resp2_p.hdl_path() == "~/calc1_sn/out_resp2";

   out_data2_p : in simple_port of uint(bits:32) is instance; // read by sn
   keep out_data2_p.hdl_path() == "~/calc1_sn/out_data2";

   req3_cmd_in_p : out simple_port of uint(bits:4) is instance; // driven by sn
   keep req3_cmd_in_p.hdl_path() == "~/calc1_sn/req3_cmd_in";

   req3_data_in_p : out simple_port of uint(bits:32) is instance; // driven by sn
   keep req3_data_in_p.hdl_path() == "~/calc1_sn/req3_data_in";

   out_resp3_p : in simple_port of uint(bits:2) is instance; // read by sn
   keep out_resp3_p.hdl_path() == "~/calc1_sn/out_resp3";

   out_data3_p : in simple_port of uint(bits:32) is instance; // read by sn
   keep out_data3_p.hdl_path() == "~/calc1_sn/out_data3";

   req4_cmd_in_p : out simple_port of uint(bits:4) is instance; // driven by sn
   keep req4_cmd_in_p.hdl_path() == "~/calc1_sn/req4_cmd_in";

   req4_data_in_p : out simple_port of uint(bits:32) is instance; // driven by sn
   keep req4_data_in_p.hdl_path() == "~/calc1_sn/req4_data_in";

   out_resp4_p : in simple_port of uint(bits:2) is instance; // read by sn
   keep out_resp4_p.hdl_path() == "~/calc1_sn/out_resp4";

   out_data4_p : in simple_port of uint(bits:32) is instance; // read by sn
   keep out_data4_p.hdl_path() == "~/calc1_sn/out_data4";  


   instructions_to_drive : list of instruction_s;


   event clk is fall(clk_p$)@sim;
   event resp1 is change(out_resp1_p$)@sim;
   event resp2 is change(out_resp2_p$)@sim;
   event resp3 is change(out_resp3_p$)@sim;
   event resp4 is change(out_resp4_p$)@sim;

   drive_reset() @clk is {
      var i : int;

      for { i=0; i<=8; i+=1 } do {

         reset_p$ = 1111111;
         wait cycle;

      }; // for

      reset_p$ = 0000000;

   }; // drive_reset


   drive_instruction(ins : instruction_s, i : int) @clk is {

      // display generated command and data
      outf("Command %s on port %s = %s\n", i, ins.port, ins.cmd_in);
      out("Op1     = ", ins.din1);
      out("Op2     = ", ins.din2);
      out();

      // drive data into calculator port 1
      case ins.port {
      	   1: {
		req1_cmd_in_p$  = pack(NULL, ins.cmd_in);
      		req1_data_in_p$ = pack(NULL, ins.din1);
	   };
	   2: {
		req2_cmd_in_p$  = pack(NULL, ins.cmd_in);
      		req2_data_in_p$ = pack(NULL, ins.din1);
	   };
           3: {
		req3_cmd_in_p$  = pack(NULL, ins.cmd_in);
      		req3_data_in_p$ = pack(NULL, ins.din1);
	   };
           4: {
		req4_cmd_in_p$  = pack(NULL, ins.cmd_in);
      		req4_data_in_p$ = pack(NULL, ins.din1);
	   };
	   default: {
	   	out("illegal instruction port");
	   };
      };
      
      wait cycle;

      case ins.port {
      	   1: {
		req1_cmd_in_p$  = 0000;
      		req1_data_in_p$ = pack(NULL, ins.din2);
	   };
	   2: {
		req2_cmd_in_p$  = 0000;
      		req2_data_in_p$ = pack(NULL, ins.din2);
	   };
           3: {
		req3_cmd_in_p$  = 0000;
      		req3_data_in_p$ = pack(NULL, ins.din2);
	   };
           4: {
		req4_cmd_in_p$  = 0000;
      		req4_data_in_p$ = pack(NULL, ins.din2);
	   };
	   default: {
	   	out("illegal instruction port");
	   };
      };
         
   }; // drive_instruction


   collect_response(ins : instruction_s) @clk is {

      case ins.port {
      	   1: {
                wait @resp1; -- wait for the response
		ins.resp = out_resp1_p$;
		ins.dout = out_data1_p$;
	   };
	   2: {
                wait @resp2; -- wait for the response
		ins.resp = out_resp2_p$;
		ins.dout = out_data2_p$;
	   };
           3: {
                wait @resp3; -- wait for the response
		ins.resp = out_resp3_p$;
		ins.dout = out_data3_p$;
	   };
           4: {
                wait @resp4; -- wait for the response
		ins.resp = out_resp4_p$;
		ins.dout = out_data4_p$;
	   };
	   default: {
	   	out("illegal instruction port");
	   };
      };

   }; // collect_response


   drive() @clk is {

      drive_reset();

      for each (ins) in instructions_to_drive do {
       
         drive_instruction(ins, index);
         collect_response(ins);
         ins.check_response(ins);
         wait cycle;

      }; // for each instruction

      wait [10] * cycle;
      stop_run();

   }; // drive


   run() is also {
      start drive();        // spawn
   }; // run

}; // unit driver_u


'>

