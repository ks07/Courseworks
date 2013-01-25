module encrypt_v2( input  wire            clk,
                   input  wire            req,
                   output wire            ack,

                   input  wire [ 79 : 0 ]   K,
                   input  wire [ 63 : 0 ]   M,
                   output wire [ 63 : 0 ]   C );

   reg  [ 63 : 0 ] 			    rndOut;
   reg  [ 79 : 0 ] 			    ksOut;
   reg  [  4 : 0 ] 			    keyCounter;
   reg 					    ackReg;
   reg 	[ 63 : 0 ]			    kaReg;

   wire [ 63 : 0 ] 			    outWire;
   wire [ 63 : 0 ] 			    rndOutWire;
   wire [ 79 : 0 ] 			    ksOutWire;

   initial begin:init0
      ackReg = 0;
      kaReg = 0;
      keyCounter = 5'b00000;
   end
   
   round r0( rndOutWire, rndOut, ksOut );
   key_schedule ks0( ksOutWire, ksOut, keyCounter );
   
   always @ ( posedge clk ) begin
      if( req == 1'b1 ) begin
	 if ( keyCounter == 5'b11111 ) begin
	    // Last iteration, output results.
	    #1 rndOut = rndOutWire;
	    ksOut = ksOutWire;
	    
	    #1 kaReg = outWire;
	    #1 ackReg = 1;
	 end else if ( keyCounter == 5'b00000 ) begin
	    // First iteration, get input.
	    rndOut = M;
	    ksOut = K;
	    keyCounter = 5'b00001;
	 end else begin
	    // Set the input registers of the round and key_schedule modules to their next values.
	    #1 rndOut = rndOutWire;
	    ksOut = ksOutWire;
	    keyCounter = keyCounter + 5'b00001;
	 end
      end else begin
	 keyCounter = 5'b00000;
	 ackReg = 0;
      end
   end

   key_addition ka0( outWire, rndOut, ksOut );
   assign C = kaReg;
   assign ack = ackReg;
   
endmodule
