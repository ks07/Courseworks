module calc1_driver(c_clk, reset, req_cmd_out[1], req_data_out[1], req_cmd_out[2], req_data_out[2], req_cmd_out[3], req_data_out[3], req_cmd_out[4], req_data_out[4]);
   
   output reg 	     c_clk;
   output reg [0:3]  req_cmd_out  [1:4];
   output reg [0:31] req_data_out [1:4];
   output reg [1:7]  reset;
   
   // Define some constants.
   localparam        CMD_NOP = 0;
   localparam        CMD_ADD = 1;
   localparam        CMD_SUB = 2;
   localparam        CMD_LSH = 5;
   localparam        CMD_RSH = 6;

   // Temp variables
   integer 	     i;

   // Initialise the design inputs and the clock to 0.
   initial
     begin
	c_clk = 0;
	for (i = 1; i < 5; i = i + 1)
	  begin
	     req_data_out[i] = 0;
	     req_cmd_out[i] = CMD_NOP;
	  end
     end

   // Drive the clock every 100ns.
   always #100 c_clk = ~c_clk;

   // Task-ified tests.

   // TEST 2.1.1.1
   // 0xFFFF0000 + 0x0000FFFF
   task TEST_2_1_1_1;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'hFFFF0000;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'h0000FFFF;
      end
   endtask // TEST_2_1_1_1
   
   initial
     begin

	// TEST 1.1.1
	// Drive reset bit 1 to init the design.
	reset[1] = 1;
	#200
	  reset[1] = 0;

	// Run on all 4 ports.
	for (i = 1; i < 5; i = i + 1)
	  begin
	     TEST_2_1_1_1(i);
	  end
	
	// # 400
	//   req_cmd_out[2] = CMD_SUB;
	// req_data_out[2] = 1;
	

	// # 200
	//   req_cmd_out[2] = CMD_NOP;
	// req_data_out[2] = 100;
	
	// # 100
	//   req_cmd_out[3] = CMD_ADD;
	// req_data_out[3] = 1;
	// req_cmd_out[4] = CMD_ADD;
	// req_data_out[4] = 2;

	// # 200
	//   req_cmd_out[3] = CMD_NOP;
	// req_data_out[3] = 4;
	// req_cmd_out[4] = CMD_NOP;
	// req_data_out[4] = 8;
		
	#800 $stop;
	
     end

endmodule // calc1_driver
