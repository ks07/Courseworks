// Checks 2 bits for equality.
module equ_1bit( output wire                  r,
		 input  wire                  x,
		 input  wire                  y );

   wire 				      w;

   xor t0( w, x, y );
   not t1( r, w );

endmodule //equ_1bit

// Checks if 2 8 bit numbers are equal.
module equ_8bit( output wire                  r,
                 input  wire signed [ 7 : 0 ] x,
                 input  wire signed [ 7 : 0 ] y );

   wire 				      w [ 100 : 0 ];

   equ_1bit t00( w[0], x[0], y[0] );
   equ_1bit t10( w[1], x[1], y[1] );
   equ_1bit t20( w[2], x[2], y[2] );
   equ_1bit t30( w[3], x[3], y[3] );
   equ_1bit t40( w[4], x[4], y[4] );
   equ_1bit t50( w[5], x[5], y[5] );
   equ_1bit t60( w[6], x[6], y[6] );
   equ_1bit t70( w[7], x[7], y[7] );

   and t05( w[8], w[0], w[1] );
   and t25( w[9], w[2], w[3] );
   and t45( w[10], w[4], w[5] );
   and t65( w[11], w[6], w[7] );

   and t15( w[12], w[8], w[9] );
   and t55( w[13], w[10], w[11] );

   and t35( r, w[12], w[13] );

endmodule
