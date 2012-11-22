module sbox_test();

  wire [ 3 : 0 ] t_r;
  reg  [ 3 : 0 ] t_x;

  sbox t( .r( t_r ), .x( t_x ) );

  initial begin
        $dumpfile( "sbox_test.vcd" );
        $dumplimit( 10485760 );
        $dumpvars;

    #10 $dumpon;

        if( !$value$plusargs( "x=%h", t_x ) ) begin
          $display( "warning: need a 4-bit hexadecimal value for x" );
          $display( "         e.g., +x=3 or +x=A"                   );
        end

    #10 $display( "r=%h x=%h", t_r, t_x );

    #10 $dumpoff;
    #10 $finish;
  end

endmodule
