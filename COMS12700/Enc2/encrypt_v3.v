module encrypt_v3( input  wire            clk,

                   input  wire [ 79 : 0 ]   K,
                   input  wire [ 63 : 0 ]   M,
                   output wire [ 63 : 0 ]   C );

   genvar 				    i;

   // Array of 32 64-bit wire vectors.
   reg [ 63 : 0 ] 			    rndOut [ 30 : 0];
   reg [ 79 : 0 ] 			    ksOut [ 30 : 0 ];
   wire [ 63 : 0 ] 			    rndOutWire [ 30 : 0];
   wire [ 79 : 0 ] 			    ksOutWire [ 30 : 0 ];

   reg [ 63 : 0 ] 			    CReg;
   reg [ 79 : 0 ] 			    KAks;
   reg [ 63 : 0 ] 			    KArnd;
   
   generate
      for( i = 1; i < 31; i = i + 1 )
	begin:lp0
	   // Assign a localparam with which we can generate the inputs for k.
	   localparam [ 4 : 0 ] ksCounter = 5'b00001 + i;

	   round r( rndOutWire[ i ], rndOut[ i - 1 ], ksOut[ i - 1 ] );
	   key_schedule k( ksOutWire[ i ], ksOut[ i - 1 ], ksCounter );
	end
   endgenerate

   generate
      for( i = 30; i > 0; i = i - 1 )
	begin:lp1
	   always @ ( posedge clk ) begin
	      rndOut[ i ] = rndOutWire[ i ];
	      ksOut[ i ] = ksOutWire[ i ];
	   end
	end
   endgenerate

   
   always @ ( posedge clk ) begin
      // Accept a new input, feed inputs forward.
      #1 rndOut[ 0 ] = M;
      #1 ksOut[ 0 ] = K;      
   end

   always @ ( negedge clk ) begin
      // Output the result.
      KArnd = rndOut[ 30 ];
      KAks = ksOut [ 30 ];
   end
   
   key_addition ka0( C, KArnd, KAks );

endmodule
