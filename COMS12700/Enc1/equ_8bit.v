module equ_1bit( output wire                  r,
		 input  wire                  x,
		 input  wire                  y );

   wire 				      w;

   xor t0( w, x, y );
   not t1( r, w );

endmodule //equ_1bit

module equ_8bit( output wire                  r,
                 input  wire signed [ 7 : 0 ] x,
                 input  wire signed [ 7 : 0 ] y );

   wire 				      w [ 100 : 0 ];

   

endmodule
