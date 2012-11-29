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
		     input  wire            x,
		     input  wire           xs,
		     input  wire            c );

   wire 				     w[ 10 : 0 ];
   
   not t0( w[0], c );
   and t1( w[1], x, w[0] );
   and t2( w[2], y, c );
   or  t3( r, w[1], w[2] );
   
endmodule //in2_mux_28bit

// If y = 0, 1, 8, or 15, circular shift left by 1 bit.
// Otherwise, 2 bits.
module clr_28bit( output wire [ 27 : 0 ] r,
                  input  wire [ 27 : 0 ] x,
                  input  wire [  3 : 0 ] y );

   clr_28bit_2 t0( r, x );
   

endmodule
