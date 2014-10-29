module calc1_reference (out_data1, out_data2, out_data3, out_data4, out_resp1, out_resp2, out_resp3, out_resp4, c_clk, req1_cmd_in, req1_data_in, req2_cmd_in, req2_data_in, req3_cmd_in, req3_data_in, req4_cmd_in, req4_data_in, reset);

   output reg [0:31] out_data1, out_data2, out_data3, out_data4;
   output reg [0:1]  out_resp1, out_resp2, out_resp3, out_resp4;

   input         c_clk;
   input [0:3] 	 req1_cmd_in, req2_cmd_in, req3_cmd_in, req4_cmd_in;
   input [0:31]  req1_data_in, req2_data_in, req3_data_in, req4_data_in;
   input [1:7] 	 reset;

   // Use packed/unpacked arrays to make an array of vectors.
   // http://electronics.stackexchange.com/questions/99507/
   reg 		 req_busy     [1:4];
   reg [0:31] 	 req_data_buf [1:4];
   reg [0:3] 	 req_cmd_buf  [1:4];

   initial
     begin
	// Init all busy states to 0.
	req_busy[1] = 0;
	req_busy[2] = 0;
	req_busy[3] = 0;
	req_busy[4] = 0;
	out_data4 = 0;
	
     end
   
   always
     @ (negedge c_clk) begin
	//$display ("%t rb1: %d r1ci: %d\n\n", $time, req_busy[1], req1_cmd_in);
		
	// If port not busy and cmd coming in, start processing.
	if (req_busy[1] == 0 && req1_cmd_in != 0)
	  begin
	     req_busy[1] = 1;
	     req_cmd_buf[1] = req1_cmd_in;
	     req_data_buf[1] = req1_data_in;

	     // On the next clock edge, spit out the data in.
	     // Use a non-blocking delayed assign.
	     out_data1 <= #200 req_data_buf[1];
	  end
     end

endmodule // calc1_reference
