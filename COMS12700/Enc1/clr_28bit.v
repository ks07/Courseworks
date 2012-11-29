// 2 input, 1 bit multiplexer.
// If c = 0, r = xs2, else r = xs1
module in2_mux_1bit( output wire            r,
		     input  wire          xs1,
		     input  wire          xs2,
		     input  wire            c );

   wire 				     w[ 2 : 0 ];
   
   not t0( w[0], c );
   and t1( w[1], xs1, c );
   and t2( w[2], xs2, w[0] );
   or  t3( r, w[1], w[2] );
   
endmodule //in2_mux_1bit

// Interprets y to give the correct c value for use by multiplexers.
// If y = 0, 1, 8, or 15, c = 0
module clr_switch( output wire           c,
		   input wire [ 3 : 0 ]  y );

   wire 				 w [ 11 : 0 ];

   not t0( w[0], y[0] );
   not t1( w[1], y[1] );
   not t2( w[2], y[2] );
   not t3( w[3], y[3] );

   // w[5] = !y1 ^ !y2 ^ !y3
   and t4( w[4], w[1], w[2] );
   and t5( w[5], w[3], w[4] );

   // w[7] = !y0 ^ !y1 ^ !y2
   and t6( w[6], w[0], w[1] );
   and t7( w[7], w[2], w[6] );

   // w[10] = y0 ^ y1 ^ y2 ^ y3
   and t8( w[8], y[0], y[1] );
   and t9( w[9], y[2], y[3] );
   and t10( w[10], w[8], w[9] );

   // c = w[5] v w[7] v w[10]
   or t11( w[11], w[5], w[7] );
   or t12( c, w[10], w[11] );

endmodule //clr_switch

// If y = 0, 1, 8, or 15, circular shift left by 1 bit.
// Otherwise, 2 bits.
module clr_28bit( output wire [ 27 : 0 ] r,
                  input  wire [ 27 : 0 ] x,
                  input  wire [  3 : 0 ] y );

   wire 				 c;

   clr_switch cs( c, y );
   
   in2_mux_1bit m0( r[0], x[27], x[26], c );
   in2_mux_1bit m1( r[1], x[0], x[27], c );
   in2_mux_1bit m2( r[2], x[1], x[0], c );
   in2_mux_1bit m3( r[3], x[2], x[1], c );
   in2_mux_1bit m4( r[4], x[3], x[2], c );
   in2_mux_1bit m5( r[5], x[4], x[3], c );
   in2_mux_1bit m6( r[6], x[5], x[4], c );
   in2_mux_1bit m7( r[7], x[6], x[5], c );
   in2_mux_1bit m8( r[8], x[7], x[6], c );
   in2_mux_1bit m9( r[9], x[8], x[7], c );
   in2_mux_1bit m10( r[10], x[9], x[8], c );
   in2_mux_1bit m11( r[11], x[10], x[9], c );
   in2_mux_1bit m12( r[12], x[11], x[10], c );
   in2_mux_1bit m13( r[13], x[12], x[11], c );
   in2_mux_1bit m14( r[14], x[13], x[12], c );
   in2_mux_1bit m15( r[15], x[14], x[13], c );
   in2_mux_1bit m16( r[16], x[15], x[14], c );
   in2_mux_1bit m17( r[17], x[16], x[15], c );
   in2_mux_1bit m18( r[18], x[17], x[16], c );
   in2_mux_1bit m19( r[19], x[18], x[17], c );
   in2_mux_1bit m20( r[20], x[19], x[18], c );
   in2_mux_1bit m21( r[21], x[20], x[19], c );
   in2_mux_1bit m22( r[22], x[21], x[20], c );
   in2_mux_1bit m23( r[23], x[22], x[21], c );
   in2_mux_1bit m24( r[24], x[23], x[22], c );
   in2_mux_1bit m25( r[25], x[24], x[23], c );
   in2_mux_1bit m26( r[26], x[25], x[24], c );
   in2_mux_1bit m27( r[27], x[26], x[25], c );

endmodule
