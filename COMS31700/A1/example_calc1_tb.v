`uselib lib=calc1_black_box

module example_calc1_tb;

   wire [0:31]   out_data1, out_data2, out_data3, out_data4;
   wire [0:1]    out_resp1, out_resp2, out_resp3, out_resp4;
   
   reg 	         c_clk;
   reg [0:3] 	 req1_cmd_in, req2_cmd_in, req3_cmd_in, req4_cmd_in;
   reg [0:31]    req1_data_in, req2_data_in, req3_data_in, req4_data_in;
   reg [1:7] 	 reset;

   calc1 DUV(out_data1, out_data2, out_data3, out_data4, out_resp1, out_resp2, out_resp3, out_resp4, c_clk, req1_cmd_in, req1_data_in, req2_cmd_in, req2_data_in, req3_cmd_in, req3_data_in, req4_cmd_in, req4_data_in, reset);
   
   initial 
     begin
	c_clk = 0;
	req1_cmd_in = 0;
	req1_data_in = 0;
	req2_cmd_in = 0;
	req2_data_in = 0;
	req3_cmd_in = 0;
	req3_data_in = 0;
	req4_cmd_in = 0;
	req4_data_in = 0;
     end   
	
   always #100 c_clk = ~c_clk;
   
   initial
     begin

        // First drive reset. Driving bit 1 is enough to reset the design.

	reset[1] = 1;
	#800 
	reset[1] = 0;

	// TEST 1: 1h + 1FF_FFFFh = 200_0000 ?

        #400
	  
        req1_cmd_in = 1;
	req1_data_in = 32'b0000_0000_0000_0000_0000_0000_0000_0001;
	req2_cmd_in = 0;
	req2_data_in = 0;
	req3_cmd_in = 0;
	req3_data_in = 0;
	req4_cmd_in = 0;
	req4_data_in = 0;

	#200
	
	req1_cmd_in = 0;
	req1_data_in = 32'b0001_1111_1111_1111_1111_1111_1111_1111;
				
	// TEST 2: 1FF_FFFFh + 1FF_FFFFh =  3FFF_FFFE ?

        #400
	  
        req1_cmd_in = 1;
	req1_data_in = 32'h1FFF_FFFF;
	req2_cmd_in = 0;
	req2_data_in = 0;
	req3_cmd_in = 0;
	req3_data_in = 0;
	req4_cmd_in = 0;
	req4_data_in = 0;

	#200
	
	req1_cmd_in = 0;
	req1_data_in = 32'h1FFF_FFFF;
				
	// TEST 3: 0+0=0 ?

	#400 

        req1_cmd_in = 1;
	req1_data_in = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
	req2_cmd_in = 0;
	req2_data_in = 0;
	req3_cmd_in = 0;
	req3_data_in = 0;
	req4_cmd_in = 0;
	req4_data_in = 0;

	#200
	
	req1_cmd_in = 0;
	req1_data_in = 32'b0000_0000_0000_0000_0000_0000_0000_0000;

	#2000 $stop;

     end // initial begin

   always
     @ (reset or req1_cmd_in or req1_data_in or req2_cmd_in or req2_data_in or req3_cmd_in or req3_data_in or req4_cmd_in or req4_data_in) begin
	
	$display ("%t: r:%b \n 1c:%d,1d:%d \n 2c:%d,2d:%d \n 3c:%d,3d:%d \n 4c:%d,4d:%d \n 1r:%d,1d:%d \n 2r:%d,2d:%d \n 3r:%d,3d:%d \n 4r:%d,4d:%d \n\n", $time, reset[1], req1_cmd_in, req1_data_in, req2_cmd_in, req2_data_in, req3_cmd_in, req3_data_in, req4_cmd_in, req4_data_in, out_resp1, out_data1, out_resp2, out_data2, out_resp3, out_data3, out_resp4, out_data4);
	
     end

endmodule // example_calc1_tb
