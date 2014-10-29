module calc1_reference (out_data1, out_data2, out_data3, out_data4, out_resp1, out_resp2, out_resp3, out_resp4, c_clk, req1_cmd_in, req1_data_in, req2_cmd_in, req2_data_in, req3_cmd_in, req3_data_in, req4_cmd_in, req4_data_in, reset);

   output reg [0:31] out_data1, out_data2, out_data3, out_data4;
   output reg [0:1]  out_resp1, out_resp2, out_resp3, out_resp4;

   input         c_clk;
   input [0:3] 	 req1_cmd_in, req2_cmd_in, req3_cmd_in, req4_cmd_in;
   input [0:31]  req1_data_in, req2_data_in, req3_data_in, req4_data_in;
   input [1:7] 	 reset;

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

   localparam DATA_MAX = (2 ** 32) - 1;
   
   // Use packed/unpacked arrays to make an array of vectors.
   // http://electronics.stackexchange.com/questions/99507/
   reg 		 req_busy       [1:4];
   reg [0:31] 	 req_data_buf_A [1:4];
   reg [0:31] 	 req_data_buf_B [1:4];
   reg [0:3] 	 req_cmd_buf    [1:4];

   // Init code for reference model.
   initial
     begin
	// Init all busy states to 0.
	req_busy[1] = 0;
	req_busy[2] = 0;
	req_busy[3] = 0;
	req_busy[4] = 0;
     end

   // Task definitions for calc functions
   task OP_ADD;
      input  [0:31] d1;
      input  [0:31] d2;
      output [0:31] r; // Result
      output [0:1]  s; // Response
      begin
	 s = RSP_SUCC;
	 r = d1 + d2;
      end
   endtask

   // Temp Vars. Might need two later for simultaneous shift and arithmetic?
   reg [0:31] tmp_data [1:4];
   reg [0:1]  tmp_resp [1:4];

   // Simulation and scheduling code.
   always
     @ (negedge c_clk) begin
	//$display ("%t rb1: %d r1ci: %d\n\n", $time, req_busy[1], req1_cmd_in);
		
	// If port not busy and cmd coming in, start processing.
	if (req_busy[1] == 0 && req1_cmd_in != 0)
	  begin
	     req_busy[1] = 1;
	     req_cmd_buf[1] = req1_cmd_in;
	     req_data_buf_A[1] = req1_data_in;

	     // Delay until the next negedge to read data 2.
	     @(negedge c_clk) req_data_buf_B[1] = req1_data_in;
	     $display("$t A\n", $time);
	     
	     // Do calc.
	     OP_ADD(req_data_buf_A[1], req_data_buf_B[1], tmp_data[1], tmp_resp[1]);
	     
	     // On the next clock edge (or longer when we add scheduling), spit out the data in.
	     #200
	       $display("$t B\n", $time);
	     
	     out_data1 = tmp_data[1];
	     out_resp1 = tmp_resp[1];
	     req_busy[1] = 0;

	     // Add a delay so that if we stop on a negedge the output isn't immediately removed.
	     #1 ;

	     // Reset output on next clock edge.
	     @(negedge c_clk) out_data1 = 0;
	     $display("$t C\n", $time);
	     
	     out_resp1 = 0;
	  end
     end

endmodule // calc1_reference
