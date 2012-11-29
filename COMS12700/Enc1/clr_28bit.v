// Shifts x left by 1 bit.
module clr_28bit_1( output wire [ 27 : 0 ] r,
		    input  wire [ 27 : 0 ] x );

   assign r[1] = x[0];
   assign r[2] = x[1];
   assign r[3] = x[2];
   assign r[4] = x[3];
   assign r[5] = x[4];
   assign r[6] = x[5];
   assign r[7] = x[6];
   assign r[8] = x[7];
   assign r[9] = x[8];
   assign r[10] = x[9];
   assign r[11] = x[10];
   assign r[12] = x[11];
   assign r[13] = x[12];
   assign r[14] = x[13];
   assign r[15] = x[14];
   assign r[16] = x[15];
   assign r[17] = x[16];
   assign r[18] = x[17];
   assign r[19] = x[18];
   assign r[20] = x[19];
   assign r[21] = x[20];
   assign r[22] = x[21];
   assign r[23] = x[22];
   assign r[24] = x[23];
   assign r[25] = x[24];
   assign r[26] = x[25];
   assign r[27] = x[26];
   assign r[0]  = x[27];
   
endmodule //clr_28bit_1

// Shifts x left by 2 bits.
module clr_28bit_2( output wire [ 27 : 0 ] r,
		    input  wire [ 27 : 0 ] x );

   assign r[2] = x[0];
   assign r[3] = x[1];
   assign r[4] = x[2];
   assign r[5] = x[3];
   assign r[6] = x[4];
   assign r[7] = x[5];
   assign r[8] = x[6];
   assign r[9] = x[7];
   assign r[10] = x[8];
   assign r[11] = x[9];
   assign r[12] = x[10];
   assign r[13] = x[11];
   assign r[14] = x[12];
   assign r[15] = x[13];
   assign r[16] = x[14];
   assign r[17] = x[15];
   assign r[18] = x[16];
   assign r[19] = x[17];
   assign r[20] = x[18];
   assign r[21] = x[19];
   assign r[22] = x[20];
   assign r[23] = x[21];
   assign r[24] = x[22];
   assign r[25] = x[23];
   assign r[26] = x[24];
   assign r[27] = x[25];
   assign r[0] = x[26];
   assign r[1]  = x[27];
   
endmodule //clr_28bit_2

// 2 input, 1 bit multiplexer.
module in2_mux_1bit( output wire            r,
		     input  wire          xs1,
		     input  wire          xs2,
		     input  wire            c );

   wire 				     w[ 10 : 0 ];
   
   not t0( w[0], c );
   and t1( w[1], xs1, w[0] );
   and t2( w[2], xs2, c );
   or  t3( r, w[1], w[2] );
   
endmodule //in2_mux_1bit

// If y = 0, 1, 8, or 15, circular shift left by 1 bit.
// Otherwise, 2 bits.
module clr_28bit( output wire [ 27 : 0 ] r,
                  input  wire [ 27 : 0 ] x,
                  input  wire [  3 : 0 ] y );

   wire 				 c;
   assign c = 0; // If c=0, shift 1 bit, else 2.

   wire [ 27 : 0 ] 			 shift_1;
   wire [ 27 : 0 ] 			 shift_2;

   clr_28bit_1 c1( shift_1, x );
   clr_28bit_2 c2( shift_2, x );
   
   in2_mux_1bit m0( r[0], shift_1[0], shift_2[0], c );
   in2_mux_1bit m1( r[1], shift_1[1], shift_2[1], c );
   in2_mux_1bit m2( r[2], shift_1[2], shift_2[2], c );
   in2_mux_1bit m3( r[3], shift_1[3], shift_2[3], c );
   in2_mux_1bit m4( r[4], shift_1[4], shift_2[4], c );
   in2_mux_1bit m5( r[5], shift_1[5], shift_2[5], c );
   in2_mux_1bit m6( r[6], shift_1[6], shift_2[6], c );
   in2_mux_1bit m7( r[7], shift_1[7], shift_2[7], c );
   in2_mux_1bit m8( r[8], shift_1[8], shift_2[8], c );
   in2_mux_1bit m9( r[9], shift_1[9], shift_2[9], c );
   in2_mux_1bit m10( r[10], shift_1[10], shift_2[10], c );
   in2_mux_1bit m11( r[11], shift_1[11], shift_2[11], c );
   in2_mux_1bit m12( r[12], shift_1[12], shift_2[12], c );
   in2_mux_1bit m13( r[13], shift_1[13], shift_2[13], c );
   in2_mux_1bit m14( r[14], shift_1[14], shift_2[14], c );
   in2_mux_1bit m15( r[15], shift_1[15], shift_2[15], c );
   in2_mux_1bit m16( r[16], shift_1[16], shift_2[16], c );
   in2_mux_1bit m17( r[17], shift_1[17], shift_2[17], c );
   in2_mux_1bit m18( r[18], shift_1[18], shift_2[18], c );
   in2_mux_1bit m19( r[19], shift_1[19], shift_2[19], c );
   in2_mux_1bit m20( r[20], shift_1[20], shift_2[20], c );
   in2_mux_1bit m21( r[21], shift_1[21], shift_2[21], c );
   in2_mux_1bit m22( r[22], shift_1[22], shift_2[22], c );
   in2_mux_1bit m23( r[23], shift_1[23], shift_2[23], c );
   in2_mux_1bit m24( r[24], shift_1[24], shift_2[24], c );
   in2_mux_1bit m25( r[25], shift_1[25], shift_2[25], c );
   in2_mux_1bit m26( r[26], shift_1[26], shift_2[26], c );
   in2_mux_1bit m27( r[27], shift_1[27], shift_2[27], c );

endmodule
