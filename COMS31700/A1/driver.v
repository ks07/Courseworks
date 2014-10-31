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

   localparam        PRT_LIM = 5; // Gives the upper bound 
   
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

   // TEST GROUP 2.1.1: Simple add no carry.
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

   // 0x0000FFFF + 0xFFFF0000
   task TEST_2_1_1_2;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h0000FFFF;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'hFFFF0000;
      end
   endtask // TEST_2_1_1_2
   
   // 0x55555555 + 0xAAAAAAAA
   task TEST_2_1_1_3;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h55555555;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'hAAAAAAAA;
      end
   endtask // TEST_2_1_1_3

   // 0xAAAAAAAA + 0x55555555
   task TEST_2_1_1_4;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'hAAAAAAAA;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'h55555555;
      end
   endtask // TEST_2_1_1_4

   // TEST GROUP 2.1.2: Simple subtraction no carry.
   // 0x0000FFFF - 0x0000FFFF
   task TEST_2_1_2_1;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_SUB;
	 req_data_out[i] = 32'h0000FFFF;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
      end
   endtask // TEST_2_1_2_1
   
   // 0xFFFF0000 - 0xFFFF0000
   task TEST_2_1_2_2;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_SUB;
	 req_data_out[i] = 32'hFFFF0000;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
      end
   endtask // TEST_2_1_2_2

   // TEST GROUP 2.1.3: Addition with carry.
   // 0x0000FFFF + 0x00000001
   task TEST_2_1_3_1;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h0000FFFF;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'h00000001;
      end
   endtask // TEST_2_1_3_1

   // 0x00000001 + 0x0000FFFF
   task TEST_2_1_3_2;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h00000001;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'h0000FFFF;
      end
   endtask // TEST_2_1_3_2

   // 0x7FFF8000 + 0x00008000
   task TEST_2_1_3_3;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h7FFF8000;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'h00008000;
      end
   endtask // TEST_2_1_3_3

   // 0x00008000 + 0x7FFF8000
   task TEST_2_1_3_4;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h00008000;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'h7FFF8000;
      end
   endtask // TEST_2_1_3_4

   // 0x55555555 + 0x55555555
   task TEST_2_1_3_5;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h55555555;
	 #200
	   req_cmd_out[i] = CMD_NOP;
      end
   endtask // TEST_2_1_3_5

   // 0x2AAAAAAA + 0x2AAAAAAA
   task TEST_2_1_3_6;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h2AAAAAAA;
	 #200
	   req_cmd_out[i] = CMD_NOP;
      end
   endtask // TEST_2_1_3_6

   // TEST GROUP 2.1.4: Subtraction with carry.
   // 0x80000000 - 0x00000001
   task TEST_2_1_4_1;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_SUB;
	 req_data_out[i] = 32'h00000001;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'h80000000;
      end
   endtask // TEST_2_1_4_1
   
   // 0xFFFF0000 - 0x0000FFFF
   task TEST_2_1_4_2;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_SUB;
	 req_data_out[i] = 32'h0000FFFF;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'hFFFF0000;
      end
   endtask // TEST_2_1_4_2
   
   // 0xAAAAAAAA - 0x55555555
   task TEST_2_1_4_3;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_SUB;
	 req_data_out[i] = 32'h55555555;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'hAAAAAAAA;
      end
   endtask // TEST_2_1_4_3
   
   // 0x55555555 - 0x2AAAAAAA
   task TEST_2_1_4_4;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_SUB;
	 req_data_out[i] = 32'h2AAAAAAA;
	 # 200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'h55555555;
      end
   endtask // TEST_2_1_4_1

   // TEST GROUP 2.2.1: Boundary addition results.
   
   // 0x00000000 + 0x00000000
   task TEST_2_2_1_1;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h00000000;
	 #200
	   req_cmd_out[i] = CMD_NOP;
      end
   endtask // TEST_2_2_1_1

   // 0xFFFFFFFF + 0x00000000
   task TEST_2_2_1_2;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'hFFFFFFFF;
	 #200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'h00000000;
      end
   endtask // TEST_2_2_1_2

   // 0x00000000 + 0xFFFFFFFF
   task TEST_2_2_1_3;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_ADD;
	 req_data_out[i] = 32'h00000000;
	 #200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'hFFFFFFFF;
      end
   endtask // TEST_2_2_1_3
   
   // TEST GROUP 2.2.2: Boundary subtraction results.
   
   // 0x00000000 - 0x00000000
   task TEST_2_2_2_1;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_SUB;
	 req_data_out[i] = 32'h00000000;
	 #200
	   req_cmd_out[i] = CMD_NOP;
      end
   endtask // TEST_2_2_2_1

   // 0xFFFFFFFF - 0xFFFFFFFF
   task TEST_2_2_2_2;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_SUB;
	 req_data_out[i] = 32'hFFFFFFFF;
	 #200
	   req_cmd_out[i] = CMD_NOP;
      end
   endtask // TEST_2_2_2_2

   // 0xFFFFFFFF - 0x00000000
   task TEST_2_2_2_3;
      input integer i;
      begin
	 #200
	   req_cmd_out[i] = CMD_SUB;
	 req_data_out[i] = 32'h00000000;
	 #200
	   req_cmd_out[i] = CMD_NOP;
	 req_data_out[i] = 32'hFFFFFFFF;
      end
   endtask // TEST_2_2_2_3
   
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
	     $display ("Driving Test 2.1.1.1 [port=%0d]", i);
	     TEST_2_1_1_1(i);
	  end
	
	// Run on all 4 ports.
	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.1.2 [port=%0d]", i);
	     TEST_2_1_1_2(i);
	  end
	
	// Run on all 4 ports.
	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.1.3 [port=%0d]", i);
	     TEST_2_1_1_3(i);
	  end
	
	// Run on all 4 ports.
	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.1.4 [port=%0d]", i);
	     TEST_2_1_1_4(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.2.1 [port=%0d]", i);
	     TEST_2_1_2_1(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.2.2 [port=%0d]", i);
	     TEST_2_1_2_2(i);
	  end
	
	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.3.1 [port=%0d]", i);
	     TEST_2_1_3_1(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.3.2 [port=%0d]", i);
	     TEST_2_1_3_2(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.3.3 [port=%0d]", i);
	     TEST_2_1_3_3(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.3.4 [port=%0d]", i);
	     TEST_2_1_3_4(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.3.5 [port=%0d]", i);
	     TEST_2_1_3_5(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.3.6 [port=%0d]", i);
	     TEST_2_1_3_6(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.4.1 [port=%0d]", i);
	     TEST_2_1_4_1(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.4.2 [port=%0d]", i);
	     TEST_2_1_4_2(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.4.3 [port=%0d]", i);
	     TEST_2_1_4_3(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.1.4.4 [port=%0d]", i);
	     TEST_2_1_4_4(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.2.1.1 [port=%0d]", i);
	     TEST_2_2_1_1(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.2.1.1 [port=%0d]", i);
	     TEST_2_2_1_2(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.2.1.3 [port=%0d]", i);
	     TEST_2_2_1_3(i);
	  end
	
	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.2.2.1 [port=%0d]", i);
	     TEST_2_2_2_1(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.2.2.2 [port=%0d]", i);
	     TEST_2_2_2_2(i);
	  end

	for (i = 1; i < 5; i = i + 1)
	  begin
	     $display ("Driving Test 2.2.2.3 [port=%0d]", i);
	     TEST_2_2_2_3(i);
	  end
	
	#800 $stop;
	
     end

endmodule // calc1_driver
