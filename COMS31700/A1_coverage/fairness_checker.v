module calc1_fairness(req_cmd_in, duv_out_resp, enable, please);

   input [0:3]    req_cmd_in [1:4];
   input [0:1] 	  duv_out_resp [1:4];
   input 	  enable;
   output integer please;
   
   time 	in_time [1:4];
   time 	total_time [1:4];
   integer 	requests [1:4];
   integer 	was_enabled;
   
   // Temp
   integer 	i;
   genvar 	ii;
   
   initial
     begin
	was_enabled = 0;
	for (i = 1; i < 5; i = i + 1)
	  begin
	     requests[i] = 0;
	     total_time[i] = 0;
	  end
     end

   generate for (ii = 1; ii < 5; ii = ii + 1)
     begin
	always
	  @ (req_cmd_in[ii]) begin
	     // On cmd input event, if > 0 then take the time.
	     if (enable && req_cmd_in[ii] > 0)
	       begin
		  in_time[ii] = $time;
		  wait (duv_out_resp[ii][1])
		    begin
		       total_time[ii] = total_time[ii] + ($time - in_time[ii]);
		       requests[ii] = requests[ii] + 1;
		       // Send request for a new command here.
		       please = ii;
		    end
	       end
	  end // always @ (req_cmd_in[ii])
     end // for (ii = 1; ii < 5; ii = ii + 1)
   endgenerate

   always
     @ (enable) begin
	// When enable goes low, print our findings.
	if (enable && !was_enabled)
	  begin
	     was_enabled = 1;
	  end
	else if (!enable && was_enabled)
	  begin
	     $display ("FAIRNESS/TIMING REPORT:");
	     for (i = 1; i < 5; i = i + 1)
	       begin
		  $display ("\tPort %0d: Response time: %0d over %0d requests", i, total_time[i], requests[i]);
	       end
	  end
     end // always @ (enable)
   
endmodule // calc1_fairness
