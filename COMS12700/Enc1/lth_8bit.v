// Calculates if x is less than y. (r = 1 if x < y)
module lth_8bit( output wire                  r,
                 input  wire signed [ 7 : 0 ] x,
                 input  wire signed [ 7 : 0 ] y );

   wire 			    [ 7 : 0 ] w;
   wire 				      op;
   wire                                       ci;
   wire 				      of;
   
   assign op = 1;
   assign ci = 0;
 				      
   // Use sub_8bit module from sub_8bit.v. Verilog will automatically search files in the
   // same directory when looking for sub_8bit.
   sub_8bit s0( op, of, w, ci, x, y );

   xor t0( r, w[7], of );
   
endmodule
