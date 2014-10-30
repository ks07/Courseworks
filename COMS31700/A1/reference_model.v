module calc1_reference (out_data[1], out_data[2], out_data[3], out_data[4], out_resp[1], out_resp[2], out_resp[3], out_resp[4], c_clk, req_cmd_in[1], req_data_in[1], req_cmd_in[2], req_data_in[2], req_cmd_in[3], req_data_in[3], req_cmd_in[4], req_data_in[4], reset);

   output reg [0:31] out_data [1:4];
   output reg [0:1]  out_resp [1:4];

   input 	     c_clk;
   input [0:3] 	     req_cmd_in  [1:4];
   input [0:31]      req_data_in [1:4];
   input [1:7] 	     reset;

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
   integer    i; // Temp counter
   

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
   task OP;
      input  [0:3]  cmd;
      input  [0:31] d1;
      input  [0:31] d2;
      output [0:31] r; // Result
      output [0:1]  s; // Response
      begin
	 // TODO: Support shift and set overflow/error responses.
	 s = RESP_SUCC;
	 
	 if (cmd == CMD_ADD)
	   begin
	      r = d1 + d2;
	   end
	 else if (cmd == CMD_SUB)
	   begin
	      $display("Calculating %d - %d", d2, d1);
	      r = d2 - d1;
	   end
	 else
	   begin
	      s = RESP_INOF;
	      $display("%t UNIMPLEMENTED COMMAND %d\n", $time, cmd);
	   end
      end
   endtask

   // Simulation and scheduling code.
   always
     @ (negedge c_clk) begin
	$display ("%t Pipe State: %d %d %d %d\n\n", $time, pipe_state[1], pipe_state[2], pipe_state[3], pipe_state[4]);
	for (i = 1; i < 5; i = i + 1)
	  begin
	     if (pipe_state[i] == STATE_IDLE)
	       begin
		  // Reset this stream's output.
		  out_resp[i] = RESP_NONE;
		  out_data[i] = 0;
	     
		  if (req_cmd_in[i] != 0)
		    begin
		       req_data_buf_A[i] = req_data_in[i];
		       req_cmd_buf[i] = req_cmd_in[i];
		       pipe_state[i] = STATE_DATA;
		    end
	       end
	     else if (pipe_state[i] == STATE_DATA)
	       begin
		  req_data_buf_B[i] = req_data_in[i];
		  pipe_state[i] = STATE_COMP;
	       end
	     else if (pipe_state[i] == STATE_COMP)
	       begin
		  OP(req_cmd_buf[i], req_data_buf_A[i], req_data_buf_B[i], out_data[i], out_resp[i]);
	     
		  // If new cmd in jump to ODAT.
		  if (req_cmd_in[i] != 0)
		    begin
		       req_cmd_buf[i] = req_cmd_in[i];
		       req_data_buf_A[i] = req_data_in[i];
		       pipe_state[i] = STATE_ODAT;
		    end
		  else
		    begin
		       pipe_state[i] = STATE_IDLE;
		    end
	       end
	     else if (pipe_state[i] == STATE_ODAT)
	       begin
		  // We have just output a result and have part 1 of a command.
		  out_resp[i] = RESP_NONE;
		  out_data[i] = 0;
		  pipe_state[i] = STATE_COMP;
	       end
	  end // for (i = 1; i < 5; i = i + 1)
     end // always @ (negedge c_clk)

endmodule // calc1_reference
