module calc1_reference (out_data[1], out_data[2], out_data[3], out_data[4], out_resp[1], out_resp[2], out_resp[3], out_resp[4], c_clk, req_cmd_in[1], req_data_in[1], req_cmd_in[2], req_data_in[2], req_cmd_in[3], req_data_in[3], req_cmd_in[4], req_data_in[4], reset, out_prompt);

   output reg [0:31] out_data [1:4];
   output reg [0:1]  out_resp [1:4];

   input 	     c_clk;
   input [0:3] 	     req_cmd_in  [1:4];
   input [0:31]      req_data_in [1:4];
   input [1:7] 	     reset;

   // Add a new input so we can rely on the DUV to supply us output timings, as the spec leaves this undefined.
   input [0:1] 	     out_prompt [1:4];
   
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
   reg [0:31] 	 req_data_buf_A [1:4];
   reg [0:31] 	 req_data_buf_B [1:4];
   reg [0:3] 	 req_cmd_buf    [1:4];

   // Use a queue to ensure fairness of channel responses. Need one queue per op type.
   // Queue should hold the number of the channel that is waiting, in order of request time.
   // TODO: Support for simultaneous request randomisation.
   integer 	 arith_queue [$];
   integer 	 shift_queue [$];
   time 	 arith_last_op;
   time 	 shift_last_op;

   // Represent each cmd pipeline as a state machine
   localparam    STATE_IDLE = 0; // Waiting for command.
   localparam    STATE_DATA = 1; // Waiting for arg 2.
   localparam    STATE_COMP = 2; // Ready to output result. Goto 0 or 3.
   localparam    STATE_ODAT = 3; // Clear result and wait for arg2.
   localparam    STATE_DEAD = 4; // Error state and initial state, cleared by a reset signal.
   integer 	 pipe_state [1:4]; // The current state of each pipe.
   integer 	 i, j; // Temp counters.

   // The DUV only starts output after the first command is process, otherwise is floating.
   // Assume this behaviour to be correct, and emulate here.
   // TODO: Interaction with reset?
   integer 	 output_active;
   
   // Init code for reference model.
   initial
     begin
	// Init all pipe states to 0.
	pipe_state[1] = STATE_DEAD;
	pipe_state[2] = STATE_DEAD;
	pipe_state[3] = STATE_DEAD;
	pipe_state[4] = STATE_DEAD;

	// Init last op to 0.
	arith_last_op = 0;
	shift_last_op = 0;

	// Init output state to floating until first comp done.
	output_active = 0;
     end // initial begin
   
   // Task definitions for calc functions. Automatic gives variables local scope, as opposed to static.
   task automatic OP;
      input  [0:3]  cmd;
      input  [0:31] d1;
      input  [0:31] d2;
      output [0:31] r; // Result
      output [0:1]  s; // Response
      reg [0:32]    temp; // Use a wider reg to check for overflow.
      begin
	 // TODO: Support shift and set overflow/error responses.
	 s = RESP_SUCC;
	 
	 if (cmd == CMD_ADD)
	   begin
	      temp = d1 + d2;
	      if (temp[32] == 1)
		begin
		   // We have overflowed.
		   s = RESP_INOF;
		end
	      r = temp[0:31];
	   end
	 else if (cmd == CMD_SUB)
	   begin
	      //$display("Calculating %d - %d", d1, d2);
	      temp = d1 - d2;
	      if (temp[32] == 1)
		begin
		   // Overflowed (or underflow, if you prefer)
		   s = RESP_INOF;
		end
	      r = temp[0:31];
	   end
	 else if (cmd == CMD_LSH)
	   begin
	      r = d1 << d2;
	   end
	 else if (cmd == CMD_RSH)
	   begin
	      r = d1 >> d2;
	   end
	 else
	   begin
	      s = RESP_INOF;
	      $display("%t UNIMPLEMENTED COMMAND %d\n", $time, cmd);
	   end
      end
   endtask // OP

   task QUEUE;
      input [0:3] cmd;
      input integer port;
      begin
	 if (cmd == CMD_ADD || cmd == CMD_SUB)
	   begin
	      arith_queue.push_back(port);
	   end
	 else if (cmd == CMD_LSH || cmd == CMD_RSH)
	   begin
	      shift_queue.push_back(port);
	   end
      end
   endtask // QUEUE

   function integer QUEUE_GATE;
      input integer port; // TODO: Assert that we are only queue'd once
      begin
	 //$display("Checking %d\n", port);

	 // Need to check that we are both at the front of the queue and
	 // we haven't already done a computation this cycle.	 
	 if (arith_queue.size() > 0 && arith_last_op < $time)
	   begin
	      if (arith_queue[0] == port)
		begin
		   // We are at the front of the queue. Pop us off and return true.
		   void '(arith_queue.pop_front());
		   arith_last_op = $time;
		   return 1;
		end
	   end
	 else if (shift_queue.size() > 0 && shift_last_op < $time)
	   begin
	      if (shift_queue[0] == port)
		begin
		   // Pop off and ret true.
		   void '(shift_queue.pop_front());
		   shift_last_op = $time;
		   return 1;
		end
	   end // if (shift_queue.size() > 0)
	 return 0;
      end
   endfunction // QUEUE_GATE

   // From http://www.asic-world.com/systemverilog/data_types14.html
   task print_queue;
      input integer queue [$];
      integer 	    i;
      begin
	 $write("Queue contains: [");
	 for (i = 0; i < queue.size(); i ++) begin
	    $write (" %g", queue[i]);
	 end
	 $write(" ]\n");
      end
   endtask // print_queue

   genvar ii; // Special loop variable for generating the concurrent always blocks.
   
   // Simulation and scheduling code. Use a generate block to make multiple always blocks so we can run in parallel.
   generate for (ii = 1; ii < 5; ii = ii + 1)
     begin
	always
	  @ (negedge c_clk) begin
	     //$display ("%t Pipe State: %d %d %d %d\n", $time, pipe_state[1], pipe_state[2], pipe_state[3], pipe_state[4]);
	     //print_queue(arith_queue);
	     //print_queue(shift_queue);
	     
	     if (pipe_state[ii] == STATE_IDLE)
	       begin
		  // Reset this stream's output, only if the output is active.
		  if (output_active != 0)
		    begin
		       out_resp[ii] = RESP_NONE;
		       out_data[ii] = 0;
		    end
		  
		  if (req_cmd_in[ii] != 0)
		    begin
		       // We have a new request on this port, add this to the queue.
		       //QUEUE(req_cmd_in[ii], i);
		       
		       // Store inputs.
		       req_data_buf_A[ii] = req_data_in[ii];
		       req_cmd_buf[ii] = req_cmd_in[ii];
		       pipe_state[ii] = STATE_DATA;
		    end
	       end
	     else if (pipe_state[ii] == STATE_DATA)
	       begin
		  // Store second operand.
		  req_data_buf_B[ii] = req_data_in[ii];
		  pipe_state[ii] = STATE_COMP;
	       end
	     else if (pipe_state[ii] == STATE_COMP)
	       begin
		  // Only allow execution at this time if the DUV is also outputting.
		  @ (out_prompt[ii])
		    begin
		       // At front, GO GO GO!
		       
		       // Set the output active flag, and pull-down floating outputs on first comp.
		       if (output_active == 0)
			 begin
			    output_active = 1;
			    for (j = 1; j < 5; j = j + 1)
			      begin
				 // TODO: THIS WILL GO HORRIBLY WRONG.
				 // Pull down all outputs.
				 out_data[j] = 0;
				 out_resp[j] = 0;
			      end
			 end
		       
		       // Do the actual calculation.
		       OP(req_cmd_buf[ii], req_data_buf_A[ii], req_data_buf_B[ii], out_data[ii], out_resp[ii]);

		       if (out_resp[ii] == RESP_ERR || out_resp[ii] == RESP_INOF)
			 begin
			    // If we output an error state, then we need to halt this pipeline.
			    $display ("Ref pipe %0d has died @ t=%0t", ii, $time);
			    pipe_state[ii] = STATE_DEAD;
			 end
		       else if (req_cmd_in[ii] != 0)
			 begin
		       	    // If new cmd in jump to ODAT.
			    req_cmd_buf[ii] = req_cmd_in[ii];
			    req_data_buf_A[ii] = req_data_in[ii];
			    pipe_state[ii] = STATE_ODAT;
			 end
		       else
			 begin
			    // All is well, back to sleep.
			    pipe_state[ii] = STATE_IDLE;
			 end
		    end // if (QUEUE_GATE(i) == 1)
	       end // if (pipe_state[ii] == STATE_COMP)
	     else if (pipe_state[ii] == STATE_ODAT)
	       begin
		  // We have just output a result and have part 1 of a command.
		  out_resp[ii] = RESP_NONE;
		  out_data[ii] = 0;
		  pipe_state[ii] = STATE_COMP;
	       end
	     else if (pipe_state[ii] == STATE_DEAD)
	       begin
		  // This pipe is dead, either uninitialised or an internal error occurred.
		  // We must wait for a reset signal to leave this state.
		  // TODO: Reset should affect all pipes even if they aren't dead - need to compare with DUV/spec.
		  wait (reset[1]) pipe_state[ii] = STATE_IDLE;
	       end // if (pipe_state[ii] == STATE_DEAD)
	  end // always @ (negedge c_clk)
     end // for (ii = 1; ii < 5; ii = ii + 1)
   endgenerate
   
endmodule // calc1_reference
