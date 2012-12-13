module round_test();

  wire [ 63 : 0 ] t_r;
  reg  [ 63 : 0 ] t_x;
  reg  [ 79 : 0 ] t_k;

  round t( .r( t_r ), .x( t_x ), .k( t_k ) );

  initial begin
        $dumpfile( "round_test.vcd" );
        $dumplimit( 10485760 );
        $dumpvars;

    #10 $dumpon;

        if( !$value$plusargs( "x=%h", t_x ) ) begin
          $display( "warning: need an unsigned 64-bit hexadecimal value for x" );
          $display( "         e.g., +x=4A38C5E00283FBA1"                       );
        end
        if( !$value$plusargs( "k=%h", t_k ) ) begin
          $display( "warning: need an unsigned 80-bit hexadecimal value for k" );
          $display( "         e.g., +k=8BA27A0EB8783AC96D59"                   );
        end
     
    #10 $display( "r=%h x=%h k=%h", t_r, t_x, t_k );

    #10 $dumpoff;
    #10 $finish;
  end

endmodule
