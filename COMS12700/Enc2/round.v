module round( output wire [ 63 : 0 ] r, 
              input  wire [ 63 : 0 ] x, 
              input  wire [ 79 : 0 ] k );

   wire [ 63 : 0 ] 		     w;
   wire [ 63 : 0 ] 		     m;
   
   wire [ 3 : 0 ] 		     split [ 15 : 0 ];
   wire [ 3 : 0 ] 		     sbd [ 15 : 0 ];
   
   
   genvar 			     i;

   key_addition ka( w, x, k );

   split_0 sp( split[0], split[1], split[2], split[3], split[4], split[5], split[6], split[7], split[8], split[9], split[10], split[11], split[12], split[13], split[14], split[15], w );

   generate
      for( i = 0; i < 16; i = i + 1 )
	begin:lp0
	   sbox sb( sbd[i], split[i] );
	end
   endgenerate

   merge_0 mr( m, sbd[0], sbd[1], sbd[2], sbd[3], sbd[4], sbd[5], sbd[6], sbd[7], sbd[8], sbd[9], sbd[10], sbd[11], sbd[12], sbd[13], sbd[14], sbd[15] );

   perm pm( r, m );
endmodule
