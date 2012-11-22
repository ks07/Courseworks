module sub_8bit_test();

  reg                   t_op;
  wire                  t_of;
  wire signed [ 7 : 0 ] t_r;
  reg                   t_ci;
  reg  signed [ 7 : 0 ] t_x;
  reg  signed [ 7 : 0 ] t_y;

  sub_8bit t( .op( t_op ), .of( t_of ), .r( t_r ), 
                           .ci( t_ci ), .x( t_x ), .y( t_y ) );

  initial begin
        $dumpfile( "sub_8bit_test.vcd" );
        $dumplimit( 10485760 );
        $dumpvars;

    #10 $dumpon;

        if( !$value$plusargs( "op=%b", t_op ) ) begin
          $display( "warning: need a        1-bit binary  value for op" );
          $display( "         i.e., +op=0 or +op=1"                     );
        end
        if( !$value$plusargs( "ci=%b", t_ci ) ) begin
          $display( "warning: need an       1-bit binary  value for ci" );
          $display( "         i.e., +ci=0 or +ci=1"                     );
        end
        if( !$value$plusargs(  "x=%d", t_x  ) ) begin
          $display( "warning: need a signed 8-bit decimal value for x"  );
          $display( "         e.g., +x=5  or +x=-7"                     );
        end
        if( !$value$plusargs(  "y=%d", t_y  ) ) begin
          $display( "warning: need a signed 8-bit decimal value for y"  );
          $display( "         e.g., +y=5  or +y=-7"                     );
        end

    #10 $display( "op=%b of=%b r=%0d ci=%b x=%0d y=%0d", t_op, t_of, t_r, t_ci, t_x, t_y );

    #10 $dumpoff;
    #10 $finish;
  end

endmodule

