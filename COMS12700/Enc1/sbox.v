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

   wire 			   c [ 8 : 0 ];
   
   // C'
   or tc0( c[0], b[0], b[2] );
   and tc1( c[1], a[0], x[1] );
   and tc2( c[2], c[0], c[1] );

   and tc3( c[3], x[3], b[0] );
   and tc4( c[4], c[3], b[2] );

   or tc5( c[5], x[2], b[1] );
   and tc6( c[6], x[0], x[3] );
   and tc7( c[7], c[5], c[6] );

   or tc8( c[8], c[2], c[4] );
   or tc9( r[1], c[8], c[7] );

   wire 			   d [ 10 : 0 ];

   // D'
   xnor td0( d[0], x[0], x[3] );
   and td1( d[1], x[2], b[1] );
   and td2( d[2], d[0], d[1] );

   xor td3( d[3], x[0], x[3] );
   or td4( d[4], b[0], x[1] );
   and td5( r[0], d[3], d[4] );

endmodule //sbox
