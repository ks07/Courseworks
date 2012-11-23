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

// Small module to simplify neg module, less repetition.
module neg_sub( input wire                 x,
		input wire                 n,
		input wire                 i,
		input wire                ci,
		output wire               ox,
		output wire               on );

   wire 				  w1, w2, w3, w4;

   xor t0( ox, x, n );
   or t1( w1, x, n );
   //not t2( w2, i );
   and t3( w3, w1, i );
   and t4( w4, i, ci );
   or t5( on, w4, w3 );
   
endmodule //neg_sub

// Takes the value of i and calculates i*(-1). For use in subtraction.
module neg( input wire signed [ 7 : 0 ]    i,
	    input wire                     a,
	    input wire                    ci,
	    output wire signed [ 7 : 0 ]   o );

   wire 				      n[ 7 : 0 ];

   assign n[0] = 0;

   neg_sub t0( i[0], n[0], a, ci, o[0], n[1] );
   neg_sub t1( i[1], n[1], a, ci, o[1], n[2] );
   neg_sub t2( i[2], n[2], a, ci, o[2], n[3] );
   neg_sub t3( i[3], n[3], a, ci, o[3], n[4] );
   neg_sub t4( i[4], n[4], a, ci, o[4], n[5] );
   neg_sub t5( i[5], n[5], a, ci, o[5], n[6] );
   neg_sub t6( i[6], n[6], a, ci, o[6], n[7] );
   neg_sub t7( i[7], n[7], a, ci, o[7], ); // Blank param => ignore output

endmodule //neg

// An 8 bit adder and subtractor with oveflow detection.
// If op = 1, r = x - y - ci, else r = x + y + ci
module sub_8bit( input  wire                  op,
                 output wire                  of,
                 output wire signed [ 7 : 0 ]  r,
                 input  wire                  ci,
                 input  wire signed [ 7 : 0 ]  x,
                 input  wire signed [ 7 : 0 ]  y );

   wire [ 7 : 0 ] 			       c;
   wire [ 7 : 0 ] 			       b;

   neg t_( y, op, ci, b );   

   full_adder t0( x[0], b[0], ci, r[0], c[0] );
   full_adder t1( x[1], b[1], c[0], r[1], c[1] );
   full_adder t2( x[2], b[2], c[1], r[2], c[2] );
   full_adder t3( x[3], b[3], c[2], r[3], c[3] );
   full_adder t4( x[4], b[4], c[3], r[4], c[4] );
   full_adder t5( x[5], b[5], c[4], r[5], c[5] );
   full_adder t6( x[6], b[6], c[5], r[6], c[6] );
   full_adder t7( x[7], b[7], c[6], r[7], of );

endmodule //sub_8bit