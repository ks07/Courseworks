`include "reference_model.v"
`uselib lib=calc1_black_box

module calc1_driver;

   wire [0:31]   out_data [1:4];
   wire [0:1] 	 out_resp [1:4];
   
   reg 	         c_clk;
   reg [0:3] 	 req_cmd_in [1:4];
   reg [0:31]    req_data_in [1:4];
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
   calc1_reference CREF(out_data[1], out_data[2], out_data[3], out_data[4], out_resp[1], out_resp[2], out_resp[3], out_resp[4], c_clk, req_cmd_in[1], req_data_in[1], req_cmd_in[2], req_data_in[2], req_cmd_in[3], req_data_in[3], req_cmd_in[4], req_data_in[4], reset);
   
   initial
     begin
	c_clk = 0;
	req_data_in[1] = 0;
     end

   always #100 c_clk = ~c_clk;

   initial
     begin

	# 200
	  req_cmd_in[1] = CMD_ADD;
	req_data_in[1] = 255;

	# 100
	  req_cmd_in[1] = CMD_NOP;

	# 400
	  req_cmd_in[2] = CMD_SUB;
	req_data_in[2] = 1;
	

	# 200
	  req_cmd_in[2] = CMD_NOP;
	req_data_in[2] = 100;
	
	# 100
	  req_cmd_in[3] = CMD_ADD;
	req_data_in[3] = 1;
	req_cmd_in[4] = CMD_ADD;
	req_data_in[4] = 2;

	# 200
	  req_cmd_in[3] = CMD_NOP;
	req_data_in[3] = 4;
	req_cmd_in[4] = CMD_NOP;
	req_data_in[4] = 8;
		
	#800 $stop;
	
     end

endmodule // calc1_driver
