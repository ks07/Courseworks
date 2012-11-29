// A substitution box, implementing the PRESENT block cipher.
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

   wire 			   b [ 14 : 0 ];

   // B'
   not tb0( b[0], x[2] );
   not tb1( b[1], x[1] );
   not tb2( b[2], x[0] );

   and tb3( b[3], a[0], b[0] );
   and tb4( b[4], b[1], b[3] );

   and tb5( b[5], a[0], x[2] );
   and tb6( b[6], x[1], x[0] );
   and tb7( b[7], b[5], b[6] );

   and tb8( b[8], x[1], b[2] );
   and tb9( b[9], b[8], b[0] );

   and tb10( b[10], b[1], x[3] );
   or tb11( b[11], x[2], x[0] );
   and tb12( b[12], b[10], b[11] );
   
   or tb13( b[13], b[4], b[7] );
   or tb14( b[14], b[9], b[12] );
   or tb15( r[2], b[14], b[13] );

   assign r[1] = 0;
   assign r[0] = 0;
   

endmodule                
