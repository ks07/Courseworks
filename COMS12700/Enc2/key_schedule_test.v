module key_schedule_test();

  wire [ 79 : 0 ] t_r;
  reg  [ 79 : 0 ] t_x;
  reg  [  4 : 0 ] t_i;

  key_schedule t( .r( t_r ), .x( t_x ), .i( t_i ) );

  initial begin
        $dumpfile( "key_schedule_test.vcd" );
        $dumplimit( 10485760 );
        $dumpvars;

    #10 $dumpon;

        if( !$value$plusargs( "x=%h", t_x ) ) begin
          $display( "warning: need an unsigned 80-bit hexadecimal value for x" );
          $display( "         e.g., +x=8BA27A0EB8783AC96D59"                   );
        end
        if( !$value$plusargs( "i=%h", t_i ) ) begin
          $display( "warning: need an unsigned  5-bit hexadecimal value for i" );
          $display( "         e.g., +i=1F"                                     );
        end
     
    #10 $display( "r=%h x=%h i=%h", t_r, t_x, t_i );

    #10 $dumpoff;
    #10 $finish;
  end

endmodule
