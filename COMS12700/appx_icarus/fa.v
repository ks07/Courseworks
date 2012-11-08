module fa( output wire co,
	   output wire s,
	   input wire ci,
	   input wire x,
	   input wire y );

   wire 	      w0, w1, w2;

   xor t2( s, w0, ci );
   and t1( w1, x, y );
   
   xor t0( w0, x, y );
   and t3( w2, w0, ci );

   or t4( co, w1, w2 );

endmodule