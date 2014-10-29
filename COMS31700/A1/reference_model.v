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

   localparam RESP_NONE = 0;
   localparam RESP_SUCC = 1;
   localparam RESP_INOF = 2; // Invalid command or overflow
   localparam RESP_IERR = 3;

   localparam DATA_MAX = (2 ** 32) - 1;
   
   // Use packed/unpacked arrays to make an array of vectors.
   // http://electronics.stackexchange.com/questions/99507/
   reg 		 req_busy       [1:4];
   reg [0:31] 	 req_data_buf_A [1:4];
   reg [0:31] 	 req_data_buf_B [1:4];
   reg [0:3] 	 req_cmd_buf    [1:4];
   // Temp Vars. Might need two later for simultaneous shift and arithmetic?
   reg [0:31] tmp_data [1:4];
   reg [0:1]  tmp_resp [1:4];

   // Represent each cmd pipeline as a state machine
   localparam STATE_IDLE = 0; // Waiting for command.
   localparam STATE_DATA = 1; // Waiting for arg 2.
   localparam STATE_COMP = 2; // Ready to output result. Goto 0 or 3.
   localparam STATE_ODAT = 3; // Clear result and wait for arg2.
   integer    pipe_state [1:4]; // The current state of each pipe.

   // Init code for reference model.
   initial
     begin
	// Init all busy states to 0.
	req_busy[1] = 0;
	req_busy[2] = 0;
	req_busy[3] = 0;
	req_busy[4] = 0;
	// Init all pipe states to 0.
	pipe_state[1] = STATE_IDLE;
	pipe_state[2] = STATE_IDLE;
	pipe_state[3] = STATE_IDLE;
	pipe_state[4] = STATE_IDLE;
     end

   // Task definitions for calc functions
   task OP_ADD;
      input  [0:31] d1;
      input  [0:31] d2;
      output [0:31] r; // Result
      output [0:1]  s; // Response
      begin
	 s = RESP_SUCC;
	 r = d1 + d2;
      end
   endtask

   // Simulation and scheduling code.
   always
     @ (negedge c_clk) begin
	$display ("%t Pipe State: %d %d %d %d\n\n", $time, pipe_state[1], pipe_state[2], pipe_state[3], pipe_state[4]);

	if (pipe_state[1] == STATE_IDLE)
	  begin
	     // Reset this stream's output.
	     out_resp1 = RESP_NONE;
	     out_data1 = 0;
	     
	     if (req1_cmd_in != 0)
	       begin
		  req_data_buf_A[1] = req1_data_in;
		  req_cmd_buf[1] = req1_cmd_in;
		  pipe_state[1] = STATE_DATA;
	       end
	  end
	else if (pipe_state[1] == STATE_DATA)
	  begin
	     req_data_buf_B[1] = req1_data_in;
	     pipe_state[1] = STATE_COMP;
	  end
	else if (pipe_state[1] == STATE_COMP)
	  begin
	     out_resp1 = RESP_SUCC;
	     out_data1 = DATA_MAX;
	     
	     // If new cmd in jump to ODAT.
	     if (req1_cmd_in != 0)
	       begin
		  req_cmd_buf[1] = req1_cmd_in;
		  req_data_buf_A[1] = req1_data_in;
		  pipe_state[1] = STATE_ODAT;
	       end
	     else
	       begin
		  pipe_state[1] = STATE_IDLE;
	       end
	  end
	else if (pipe_state[1] == STATE_ODAT)
	  begin
	     // We have just output a result and have part 1 of a command.
	     out_resp1 = RESP_NONE;
	     out_data1 = 0;
	     pipe_state[1] = STATE_COMP;
	  end
     end

endmodule // calc1_reference
