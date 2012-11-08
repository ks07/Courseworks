module fa( output wire co,
	   output wire s,
	   input wire ci,
	   input wire x,
	   input wire y );

   wire 	      w[ 5 : 0 ];

   //xor t2( s, w[0], ci );
   or t2( w[3], w[0], ci );
   and t5( w[4], w[0], ci
   and t1( w[1], x, y );
   
   xor t0( w[0], x, y );
   and t3( w[2], w[0], ci );

   or t4( co, w[1], w[2] );

	   endmodule // fa

	   module altXOR(input wire w0,
			 input wire w1,
			 output wire w2);
	   
	   wire w[ 5 : 0 ];
	   
	   
	   endmodule // altXOR
	   