// Calculates if x is less than y.
module lth_8bit( output wire                  r,
                 input  wire signed [ 7 : 0 ] x,
                 input  wire signed [ 7 : 0 ] y );

   wire 			    [ 7 : 0 ] w;
   wire 				      o;
   assign o = 1;
 				      
   // Replace with sub_8bit module when complete.
   assign w = x - y;

   and t0( r, w[7], o );

endmodule
