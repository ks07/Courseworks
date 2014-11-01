module calc1_checker(c_clk, ref_out_data, ref_out_resp, duv_out_data, duv_out_resp, test_id);

   // In an ideal world, these would always be equal. But there's nothing ideal here.
   input [0:31]   ref_out_data [1:4];
   input [0:31]   duv_out_data [1:4];
   input [0:1] 	  ref_out_resp [1:4];
   input [0:1] 	  duv_out_resp [1:4];
   input 	  c_clk; // Clock for timing sync.
   input string   test_id;
   
   // Define some constants.
   localparam RSP_NONE = 0;
   localparam RSP_SUCC = 1;
   localparam RSP_INOF = 2; // Invalid command or overflow
   localparam RSP_IERR = 3;

   // Task definition to check for output discrepancies.
   task CONSISTENCY_CHECK;
      integer i; // Loop counter.
      integer port_problem;
      integer any_problem;
      begin
	 any_problem = 0;
	 $display ("CONSISTENCY CHECK AT %0t:", $time);
	 for (i = 1; i < 5; i = i + 1)
	     begin
		port_problem = 0;
		if (!(ref_out_data[i] === duv_out_data[i]))
		  begin
		     port_problem = 1;
		     $write ("\tout_data port %d", i);
		  end
		if (!(ref_out_resp[i] === duv_out_resp[i]))
		  begin
		     port_problem = 1;
		     $write ("\tout_resp port %d", i);
		  end
		if (port_problem != 0)
		  begin
		     any_problem = 1;
		     $write ("\n");
		  end
	     end // for (i = 1; i < 5; i = i + 1)
	 if (any_problem != 0)
	   begin
	      $display ("TEST %s: FAIL\n", test_id);
	   end
	 else
	   begin
	      $display ("TEST %s: PASS\n", test_id);
	   end
      end
   endtask // CONSISTENCY_CHECK
   
   always @ (negedge c_clk)
     begin
	// (Falsely) assume that outputs should always match.
	// Due to timing, this will actually flag up errors up to the instant of the clock pulse if we don't delay.
	// A delay of 0 might be possible?
	#1 CONSISTENCY_CHECK();
     end
   
endmodule // calc1_checker
