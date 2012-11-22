module lth_8bit_test();

  wire                  t_r;
  reg  signed [ 7 : 0 ] t_x;
  reg  signed [ 7 : 0 ] t_y;

  lth_8bit t( .r( t_r ), .x( t_x ), .y( t_y ) );

  initial begin
        $dumpfile( "lth_8bit_test.vcd" );
        $dumplimit( 10485760 );
        $dumpvars;

    #10 $dumpon;

        if( !$value$plusargs( "x=%d", t_x ) ) begin
          $display( "warning: need a signed 8-bit decimal value for x" );
          $display( "         e.g., +x=5 or +x=-7"                     );
        end
        if( !$value$plusargs( "y=%d", t_y ) ) begin
          $display( "warning: need a signed 8-bit decimal value for y" );
          $display( "         e.g., +y=5 or +y=-7"                     );
        end

    #10 $display( "r=%b x=%0d y=%0d", t_r, t_x, t_y );

    #10 $dumpoff;
    #10 $finish;
  end

endmodule

