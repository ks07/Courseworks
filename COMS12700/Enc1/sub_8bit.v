module full_adder( input wire                  x,
		   input wire                  y,
		   input wire                 ci,
		   output wire                 r,
		   output wire                co );

   wire 				      w[ 5 : 0 ];

   // r = (x xor y) xor ci
   xor t0( w[0], x, y );
   xor t1( r, w[0], ci );

   // co = (x and y) or (x and ci) or (y and ci)
   and t2( w[1], x, y );
   and t3( w[2], x, ci );
   and t4( w[3], y, ci );
   or t5( w[4], w[1], w[2] );
   or t6( co, w[4], w[3] );

endmodule //full_adder

module overflow_detect( output wire           of,
			input wire             x,
			input wire             y,
			input wire             r );

   wire [ 2 : 0 ] 			       w;

   // If inputs are of different signs, there will be no overflow.
   // If this is not the case, then the result should match the sign
   // of the operands.
   xor t0( w[0], x, y );
   not t1( w[1], w[0] );

   // Check if result and input signs match.
   xor t2( w[2], x, r );
   and t3( of, w[1], w[2] );

endmodule //overflow_detect
   

module sub_8bit( input  wire                  op,
                 output wire                  of,
                 output wire signed [ 7 : 0 ]  r,
                 input  wire                  ci,
                 input  wire signed [ 7 : 0 ]  x,
                 input  wire signed [ 7 : 0 ]  y );

  // fill in this module with solution
   wire [ 7 : 0 ] 			       w;
   wire [ 7 : 0 ] 			       carry;
   

   xor t0( carry[0], op, ci );
   xor t1( w[0], op, y[0] );
   xor t2( w[1], op, y[1] );
   xor t3( w[2], op, y[2] );
   xor t4( w[3], op, y[3] );
   xor t5( w[4], op, y[4] );
   xor t6( w[5], op, y[5] );
   xor t7( w[6], op, y[6] );
   xor t8( w[7], op, y[7] );

   full_adder fa0( x[0], w[0], carry[0], r[0], carry[1] );
   full_adder fa1( x[1], w[1], carry[1], r[1], carry[2] );
   full_adder fa2( x[2], w[2], carry[2], r[2], carry[3] );
   full_adder fa3( x[3], w[3], carry[3], r[3], carry[4] );
   full_adder fa4( x[4], w[4], carry[4], r[4], carry[5] );
   full_adder fa5( x[5], w[5], carry[5], r[5], carry[6] );
   full_adder fa6( x[6], w[6], carry[6], r[6], carry[7] );
   full_adder fa7( x[7], w[7], carry[7], r[7], ); //ignore final co

   overflow_detect of0( of, x[7], y[7], r[7] );

endmodule
