module sbox( output wire [ 3 : 0 ] r,
             input  wire [ 3 : 0 ] x );

   wire 			   a [ 8 : 0 ];

   // A'
   not ta0( a[0], x[3] );
   xnor ta1( a[1], x[1], x[0] );
   and ta2( a[2], x[2], x[1] );
   or ta3( a[3], a[1], a[2] );
   and ta4( a[4], a[0], a[3] );

   not ta5( a[5], x[2] );
   or ta6( a[6], x[1], x[0] );
   and ta7( a[7], x[3], a[5] );
   and ta8( a[8], a[7], a[6] );

   or ta9( r[3], a[8], a[4] );

   assign r[2] = 0;
   assign r[1] = 0;
   assign r[0] = 0;
   

endmodule                
