module encrypt_v3( input  wire            clk,

                   input  wire [ 79 : 0 ]   K,
                   input  wire [ 63 : 0 ]   M,
                   output wire [ 63 : 0 ]   C );

   genvar 				    i;
   
   integer 				    j;
   
   // Array of 32 64-bit wire vectors.
   reg [ 63 : 0 ] 			    rndOut [ 31 : 0];
   reg [ 79 : 0 ] 			    ksOut [ 31 : 0 ];
   wire [ 63 : 0 ] 			    rndOutWire [ 31 : 0];
   wire [ 79 : 0 ] 			    ksOutWire [ 31 : 0 ];

   reg [ 63 : 0 ] 			    CReg;
   reg [ 79 : 0 ] 			    KAks;
   reg [ 63 : 0 ] 			    KArnd;
   
   generate
      for( i = 0; i < 31; i = i + 1 )
	begin:lp0
	   // Assign a localparam with which we can generate the inputs for k.
	   localparam [ 4 : 0 ] ksCounter = 5'b00001 + i;

	   round r( rndOutWire[ i ], rndOut[ i ], ksOut[ i ] );
	   key_schedule k( ksOutWire[ i ], ksOut[ i ], ksCounter );
	end
   endgenerate      
      
   always @ ( posedge clk ) begin
       rndOut[ 0 ] = M;
       ksOut[ 0 ] = K;
   end


   always @ ( negedge clk ) begin
      // Output the result.

      for( j = 0; j < 31; j = j + 1 )
	begin: ladies
	    rndOut[ j + 1 ] = rndOutWire[ j ];
            ksOut[ j + 1 ] = ksOutWire[ j ];
	end


      KArnd = rndOut[ 31 ];
      KAks = ksOut [ 31 ];
   end
   
   key_addition ka0( C, KArnd, KAks );

endmodule
