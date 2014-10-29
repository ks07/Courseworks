`include "reference_model.v"
`uselib lib=calc1_black_box

module calc1_driver;

   wire [0:31]   out_data1, out_data2, out_data3, out_data4;
   wire [0:1]    out_resp1, out_resp2, out_resp3, out_resp4;
   
   reg 	         c_clk;
   reg [0:3] 	 req1_cmd_in, req2_cmd_in, req3_cmd_in, req4_cmd_in;
   reg [0:31]    req1_data_in, req2_data_in, req3_data_in, req4_data_in;
   reg [1:7] 	 reset;

   // Define some constants.
   localparam CMD_NOP = 0;
   localparam CMD_ADD = 1;
   localparam CMD_SUB = 2;
   localparam CMD_LSH = 5;
   localparam CMD_RSH = 6;

   localparam RSP_NONE = 0;
   localparam RSP_SUCC = 1;
   localparam RSP_INOF = 2; // Invalid command or overflow
   localparam RSP_IERR = 3;
   
   // Instantiate a copy of the reference model named CREF
   calc1_reference CREF(out_data1, out_data2, out_data3, out_data4, out_resp1, out_resp2, out_resp3, out_resp4, c_clk, req1_cmd_in, req1_data_in, req2_cmd_in, req2_data_in, req3_cmd_in, req3_data_in, req4_cmd_in, req4_data_in, reset);

   // Instantiate a copy of the DUV
   //calc1 DUV(out_data1, out_data2, out_data3, out_data4, out_resp1, out_resp2, out_resp3, out_resp4, c_clk, req1_cmd_in, req1_data_in, req2_cmd_in, req2_data_in, req3_cmd_in, req3_data_in, req4_cmd_in, req4_data_in, reset);
   
   initial
     begin
	c_clk = 0;
	req1_data_in = 0;
     end

   always #100 c_clk = ~c_clk;

   initial
     begin

	# 200
	  req1_cmd_in = CMD_ADD;
	req1_data_in = 255;

	# 100
	  req1_cmd_in = CMD_NOP;
	
     end

endmodule // calc1_driver
