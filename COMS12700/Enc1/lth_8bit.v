module lth_1bit( output wire                  r,
		 input  wire                  x,
		 input  wire                  y,
		 input  wire                  s );

   wire 				      w [ 2 : 0 ];
   
   not t0( w[0], x );
   and t1( w[1], y, w[0] );
   or  t2( r, s, w[1] );

endmodule //lth_1bit

// Calculates if x is less than y. (r = 1 if x < y)
module lth_8bit( output wire                  r,
                 input  wire signed [ 7 : 0 ] x,
                 input  wire signed [ 7 : 0 ] y );

   wire 			    [ 11 : 0 ] w;
   wire                                        s;

   assign s = 0;

   lth_1bit t0( w[0], x[6], y[6], s );
   lth_1bit t1( w[1], x[5], y[5], w[0] );
   lth_1bit t2( w[2], x[4], y[4], w[1] );
   lth_1bit t3( w[3], x[3], y[3], w[2] );
   lth_1bit t4( w[4], x[2], y[2], w[3] );
   lth_1bit t5( w[5], x[1], y[1], w[4] );
   lth_1bit t6( w[6], x[0], y[0], w[5] );

   not t7( w[7], y[7] );
   and t8( w[8], x[7], w[7] );
   and t9( w[9], x[7], w[6] );
   and t10( w[10], w[7], w[6] );
   or t11( w[11], w[8], w[9] );
   or t12( r, w[11], w[10] );

endmodule //lth_8bit