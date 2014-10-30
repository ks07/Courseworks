module calc1_checker(c_clk, ref_out_data, ref_out_resp, duv_out_data, duv_out_resp);

   // In an ideal world, these would always be equal. But there's nothing ideal here.
   input [0:31]   ref_out_data [1:4];
   input [0:31]   duv_out_data [1:4];
   input [0:1] 	  ref_out_resp [1:4];
   input [0:1] 	  duv_out_resp [1:4];
   input 	  c_clk; // Clock for timing sync.

   // Define some constants.
   localparam RSP_NONE = 0;
   localparam RSP_SUCC = 1;
   localparam RSP_INOF = 2; // Invalid command or overflow
   localparam RSP_IERR = 3;

   always @ (negedge c_clk)
     begin
	// (Falsely) assume that outputs should always match.
	if (ref_out_data != duv_out_data || ref_out_resp != duv_out_resp)
	  begin
	     $display ("%t INCONSISTENT OUTPUT DETECTED\n\n", $time);
	  end
     end
   
endmodule // calc1_checker
