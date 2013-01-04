module key_schedule( output wire [ 79 : 0 ] r,
                     input  wire [ 79 : 0 ] x,
                     input  wire [  4 : 0 ] i );

   wire [ 79 : 0 ] 			    rot;
   genvar 				    j;

   generate
      for( j = 0; j < 80; j = j + 1 )
	begin:lp1
	   assign rot[(j + 1) % 80] = x[j];
	end
   endgenerate

   assign r = rot;
   
endmodule
