module encrypt_v1( input  wire [ 79 : 0 ]   K,
                   input  wire [ 63 : 0 ]   M,
                   output wire [ 63 : 0 ]   C );

   genvar 				    i;

   // Array of 32 64-bit wire vectors.
   wire [ 63 : 0 ] 			    rndOut [ 30 : 0];
   wire [ 79 : 0 ] 			    ksOut [ 30 : 0 ];

   round r0( rndOut[ 0 ], M, K );
   key_schedule ks0( ksOut[ 0 ], K, 5'b00001 );
   

   generate
      for( i = 1; i < 31; i = i + 1 )
	begin:lp0
	   // Assign a localparam with which we can generate the inputs for k.
	   localparam [ 4 : 0 ] ksCounter = 5'b00001 + i;
	   
	   round r( rndOut[ i ], rndOut[ i - 1 ], ksOut[ i - 1 ] );
	   key_schedule k( ksOut[ i ], ksOut[ i - 1 ], ksCounter );
	end
   endgenerate

   key_addition ka0( C, rndOut[ 30 ], ksOut[ 30 ] );

endmodule
