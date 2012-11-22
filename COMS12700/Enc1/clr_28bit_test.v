module clr_28bit_test();

  wire [ 27 : 0 ] t_r;
  reg  [ 27 : 0 ] t_x;
  reg  [  3 : 0 ] t_y;

  clr_28bit t( .r( t_r ), .x( t_x ), .y( t_y ) );

  initial begin
        $dumpfile( "clr_28bit_test.vcd" );
        $dumplimit( 10485760 );
        $dumpvars;

    #10 $dumpon;

        if( !$value$plusargs( "x=%b", t_x ) ) begin
          $display( "warning: need a           28-bit binary  value for x" );
          $display( "         e.g., +x=1000000000000000000000000001"       );
        end
        if( !$value$plusargs( "y=%d", t_y ) ) begin
          $display( "warning: need an unsigned  4-bit decimal value for y" );
          $display( "         e.g., +y=5 or +y=7"                          );
        end

    #10 $display( "r=%b x=%b y=%0d", t_r, t_x, t_y );

    #10 $dumpoff;
    #10 $finish;
  end

endmodule
