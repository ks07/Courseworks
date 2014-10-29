module calc1_reference (out_data1, out_data2, out_data3, out_data4, out_resp1, out_resp2, out_resp3, out_resp4, c_clk, req1_cmd_in, req1_data_in, req2_cmd_in, req2_data_in, req3_cmd_in, req3_data_in, req4_cmd_in, req4_data_in, reset);

   output reg [0:31] out_data1, out_data2, out_data3, out_data4;
   output reg [0:1]  out_resp1, out_resp2, out_resp3, out_resp4;

   input         c_clk;
   input [0:3] 	 req1_cmd_in, req2_cmd_in, req3_cmd_in, req4_cmd_in;
   input [0:31]  req1_data_in, req2_data_in, req3_data_in, req4_data_in;
   input [1:7] 	 reset;

   always
     @ (negedge c_clk) begin
	
	   out_data1 = req1_data_in;
	
	
     end

endmodule // calc1_reference
