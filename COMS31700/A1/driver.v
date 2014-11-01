module calc1_driver(c_clk, reset, req_cmd_out[1], req_data_out[1], req_cmd_out[2], req_data_out[2], req_cmd_out[3], req_data_out[3], req_cmd_out[4], req_data_out[4], test_change);
   
   output reg 	     c_clk;
   output reg [0:3]  req_cmd_out  [1:4];
   output reg [0:31] req_data_out [1:4];
   output reg [1:7]  reset;

   // Define extra output to inform checker of the test end.
   output reg 	     test_change;
   
   // Define some constants.
   localparam        CMD_NOP = 0;
   localparam        CMD_ADD = 1;
   localparam        CMD_SUB = 2;
   localparam        CMD_LSH = 5;
   localparam        CMD_RSH = 6;

   localparam        PRT_LIM = 5; // Gives the upper bound of port numbers.
   
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
	test_change = 0;
     end

   // Drive the clock every 100ns.
   always #100 c_clk = ~c_clk;
   
   // Task to wait sufficient times between tests. Make an assumption about DUV response time.
   task POST_TEST;
      begin
	 // Wait 700ns to give the DUV time to settle for the next test.
	 # 700 ;
	 // Notify the checker that it should give a PASS/FAIL mark now.
	 test_change = ~test_change;
	 // Wait a further 100 to sync us back up with the clock and avoid race condition with test print.
	 # 100 ;
      end
   endtask // POST_TEST
   
   // Task to run a simple test on the driver on all 4 ports.
   task SIMPLE_TEST;
      input [0:3] cmd;
      input [0:31] arg1;
      input [0:31] arg2;
      integer 	   ii;
      begin
	 for (ii = 0; ii < PRT_LIM; ii = ii + 1)
	   begin
	      #200
		req_cmd_out[ii] = cmd;
	      req_data_out[ii] = arg1;
	      #200
		req_cmd_out[ii] = CMD_NOP;
	      req_data_out[ii] = arg2;
	   end
	 POST_TEST();
      end
   endtask // SIMPLE_TEST
   
   // Task-ified tests.

   // TEST GROUP 2.1.1: Simple add no carry.
   
   // 0xFFFF0000 + 0x0000FFFF
   task TEST_2_1_1_1;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'hFFFF0000, 32'h0000FFFF);
      end
   endtask // TEST_2_1_1_1

   // 0x0000FFFF + 0xFFFF0000
   task TEST_2_1_1_2;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h0000FFFF, 32'hFFFF0000);
      end
   endtask // TEST_2_1_1_2
   
   // 0x55555555 + 0xAAAAAAAA
   task TEST_2_1_1_3;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h55555555, 32'hAAAAAAAA);
      end
   endtask // TEST_2_1_1_3

   // 0xAAAAAAAA + 0x55555555
   task TEST_2_1_1_4;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'hAAAAAAAA, 32'h55555555);
      end
   endtask // TEST_2_1_1_4

   // TEST GROUP 2.1.2: Simple subtraction no carry.
   
   // 0x0000FFFF - 0x0000FFFF
   task TEST_2_1_2_1;
      begin
	 SIMPLE_TEST(CMD_SUB, 32'h0000FFFF, 32'h0000FFFF);
      end
   endtask // TEST_2_1_2_1
   
   // 0xFFFF0000 - 0xFFFF0000
   task TEST_2_1_2_2;
      begin
	 SIMPLE_TEST(CMD_SUB, 32'hFFFF0000, 32'hFFFF0000);
      end
   endtask // TEST_2_1_2_2

   // TEST GROUP 2.1.3: Addition with carry.
   
   // 0x0000FFFF + 0x00000001
   task TEST_2_1_3_1;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h0000FFFF, 32'h00000001);
      end
   endtask // TEST_2_1_3_1

   // 0x00000001 + 0x0000FFFF
   task TEST_2_1_3_2;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h00000001, 32'h0000FFFF);
      end
   endtask // TEST_2_1_3_2

   // 0x7FFF8000 + 0x00008000
   task TEST_2_1_3_3;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h7FFF8000, 32'h00008000);
      end
   endtask // TEST_2_1_3_3

   // 0x00008000 + 0x7FFF8000
   task TEST_2_1_3_4;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h00008000, 32'h7FFF8000);
      end
   endtask // TEST_2_1_3_4

   // 0x55555555 + 0x55555555
   task TEST_2_1_3_5;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h55555555, 32'h55555555);
      end
   endtask // TEST_2_1_3_5

   // 0x2AAAAAAA + 0x2AAAAAAA
   task TEST_2_1_3_6;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h2AAAAAAA, 32'h2AAAAAAA);
      end
   endtask // TEST_2_1_3_6

   // TEST GROUP 2.1.4: Subtraction with carry.
   
   // 0x80000000 - 0x00000001
   task TEST_2_1_4_1;
      begin
	 SIMPLE_TEST(CMD_SUB, 32'h80000000, 32'h00000001);
      end
   endtask // TEST_2_1_4_1
   
   // 0xFFFF0000 - 0x0000FFFF
   task TEST_2_1_4_2;
      begin
	 SIMPLE_TEST(CMD_SUB, 32'hFFFF0000, 32'h0000FFFF);
      end
   endtask // TEST_2_1_4_2
   
   // 0xAAAAAAAA - 0x55555555
   task TEST_2_1_4_3;
      begin
	 SIMPLE_TEST(CMD_SUB, 32'hAAAAAAAA, 32'h55555555);
      end
   endtask // TEST_2_1_4_3
   
   // 0x55555555 - 0x2AAAAAAA
   task TEST_2_1_4_4;
      begin
	 SIMPLE_TEST(CMD_SUB, 32'h55555555, 32'h2AAAAAAA);
      end
   endtask // TEST_2_1_4_4

   // TEST GROUP 2.2.1: Boundary addition results.
   
   // 0x00000000 + 0x00000000
   task TEST_2_2_1_1;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h00000000, 32'h00000000);
      end
   endtask // TEST_2_2_1_1

   // 0xFFFFFFFF + 0x00000000
   task TEST_2_2_1_2;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'hFFFFFFFF, 32'h00000000);
      end
   endtask // TEST_2_2_1_2

   // 0x00000000 + 0xFFFFFFFF
   task TEST_2_2_1_3;
      begin
	 SIMPLE_TEST(CMD_ADD, 32'h00000000, 32'hFFFFFFFF);
      end
   endtask // TEST_2_2_1_3
   
   // TEST GROUP 2.2.2: Boundary subtraction results.
   
   // 0x00000000 - 0x00000000
   task TEST_2_2_2_1;
      begin
	 SIMPLE_TEST(CMD_SUB, 32'h00000000, 32'h00000000);
      end
   endtask // TEST_2_2_2_1

   // 0xFFFFFFFF - 0xFFFFFFFF
   task TEST_2_2_2_2;
      begin
	 SIMPLE_TEST(CMD_SUB, 32'hFFFFFFFF, 32'hFFFFFFFF);
      end
   endtask // TEST_2_2_2_2

   // 0xFFFFFFFF - 0x00000000
   task TEST_2_2_2_3;
      begin
	 SIMPLE_TEST(CMD_SUB, 32'hFFFFFFFF, 32'h00000000);
      end
   endtask // TEST_2_2_2_3
   
   // TEST GROUP 3.1.1: Simple left shift
   
   task TEST_3_1_1_1;
      begin
	 SIMPLE_TEST(CMD_LSH, 32'hAAAAAAAA, 1);
      end
   endtask // TEST_3_1_1_1
      
   task TEST_3_1_1_2;
      begin
	 SIMPLE_TEST(CMD_LSH, 32'h55555555, 1);
      end
   endtask // TEST_3_1_1_2
      
   task TEST_3_1_1_3;
      begin
	 SIMPLE_TEST(CMD_LSH, 32'h0F0F0F0F, 4);
      end
   endtask // TEST_3_1_1_3
   
   // TEST GROUP 3.1.2: Simple right shift
   
   task TEST_3_1_2_1;
      begin
	 SIMPLE_TEST(CMD_RSH, 32'hAAAAAAAA, 1);
      end
   endtask // TEST_3_1_2_1
      
   task TEST_3_1_2_2;
      begin
	 SIMPLE_TEST(CMD_RSH, 32'h55555555, 1);
      end
   endtask // TEST_3_1_2_2
      
   task TEST_3_1_2_3;
      begin
	 SIMPLE_TEST(CMD_RSH, 32'hF0F0F0F0, 4);
      end
   endtask // TEST_3_1_2_3
   
   // TEST GROUP 3.2.1: Long left shift
   
   task TEST_3_2_1_1;
      begin
	 SIMPLE_TEST(CMD_LSH, 32'h00000000, 32);
      end
   endtask // TEST_3_2_1_1
      
   task TEST_3_2_1_2;
      begin
	 SIMPLE_TEST(CMD_LSH, 32'hFFFFFFFF, 32);
      end
   endtask // TEST_3_2_1_2
      
   task TEST_3_2_1_3;
      begin
	 SIMPLE_TEST(CMD_LSH, 32'h00000001, 31);
      end
   endtask // TEST_3_2_1_3
      
   task TEST_3_2_1_4;
      begin
	 SIMPLE_TEST(CMD_LSH, 32'hFFFFFFFF, 32'hFFFFFFFF);
      end
   endtask // TEST_3_2_1_4
   
   // TEST GROUP 3.2.2: Long right shift
   
   task TEST_3_2_2_1;
      begin
	 SIMPLE_TEST(CMD_RSH, 32'h00000000, 32);
      end
   endtask // TEST_3_2_2_1
      
   task TEST_3_2_2_2;
      begin
	 SIMPLE_TEST(CMD_RSH, 32'hFFFFFFFF, 32);
      end
   endtask // TEST_3_2_2_2
      
   task TEST_3_2_2_3;
      begin
	 SIMPLE_TEST(CMD_RSH, 32'h80000000, 31);
      end
   endtask // TEST_3_2_2_3
      
   task TEST_3_2_2_4;
      begin
	 SIMPLE_TEST(CMD_RSH, 32'hFFFFFFFF, 32'hFFFFFFFF);
      end
   endtask // TEST_3_2_2_4
   
   initial
     begin

	// TEST 1.1.1
	// Drive reset bit 1 to init the design.
	reset[1] = 1;
	#200
	  reset[1] = 0;
	
	$display ("Driving Test 2.1.1.1");
	TEST_2_1_1_1();
	
	$display ("Driving Test 2.1.1.2");
	TEST_2_1_1_2();
	
	$display ("Driving Test 2.1.1.3");
	TEST_2_1_1_3();
	
	$display ("Driving Test 2.1.1.4");
	TEST_2_1_1_4();

	$display ("Driving Test 2.1.2.1");
	TEST_2_1_2_1();

	$display ("Driving Test 2.1.2.2");
	TEST_2_1_2_2();
	
	$display ("Driving Test 2.1.3.1");
	TEST_2_1_3_1();
     
	$display ("Driving Test 2.1.3.2");
	TEST_2_1_3_2();
	
	$display ("Driving Test 2.1.3.3");
	TEST_2_1_3_3();
	
	$display ("Driving Test 2.1.3.4");
	TEST_2_1_3_4();
	
	$display ("Driving Test 2.1.3.5");
	TEST_2_1_3_5();
	
	$display ("Driving Test 2.1.3.6");
	TEST_2_1_3_6();
	
	$display ("Driving Test 2.1.4.1");
	TEST_2_1_4_1();
	
	$display ("Driving Test 2.1.4.2");
	TEST_2_1_4_2();
	
	$display ("Driving Test 2.1.4.3");
	TEST_2_1_4_3();
	
	$display ("Driving Test 2.1.4.4");
	TEST_2_1_4_4();
	
	$display ("Driving Test 2.2.1.1");
	TEST_2_2_1_1();
	
	$display ("Driving Test 2.2.1.2");
	TEST_2_2_1_2();
	
	$display ("Driving Test 2.2.1.3");
	TEST_2_2_1_3();
	
	$display ("Driving Test 2.2.2.1");
	TEST_2_2_2_1();
	
	$display ("Driving Test 2.2.2.2");
	TEST_2_2_2_2();
	
	$display ("Driving Test 2.2.2.3");
	TEST_2_2_2_3();
	
	#800 $stop;
	
     end // initial begin

endmodule // calc1_driver
