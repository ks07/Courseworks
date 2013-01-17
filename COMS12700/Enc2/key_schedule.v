module key_schedule( output wire [ 79 : 0 ] r,
                     input  wire [ 79 : 0 ] x,
                     input  wire [  4 : 0 ] i );

   wire [ 79 : 0 ] 			    rot;
   wire [ 3 : 0 ] 			    t1;
   
   wire [ 4 : 0 ] 			    t2;
   
 
   genvar 				    j;

   generate
      for( j = 0; j < 80; j = j + 1 )
	begin:lp1
	   assign rot[(j + 61) % 80] = x[j];
	end
   endgenerate

   sbox sb0(t1, rot[ 79 : 76 ]);
   assign t2 = rot[ 19 : 15 ] ^ i;

   assign r = {t1, rot[ 75 : 20 ], t2, rot[ 14 : 0 ]};
   
endmodule
