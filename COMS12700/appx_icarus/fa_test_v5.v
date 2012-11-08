module fa_test_v5();

  wire t_co,      t_s;
  reg  t_ci, t_x, t_y;

  fa t( .co( t_co ), .s( t_s ), .ci( t_ci ), .x( t_x ), .y( t_y ) );    

  initial begin
        $dumpfile( "fa_test_v5.vcd" );
        $dumplimit( 10485760 );
        $dumpvars;

    #10 $dumpon;

    #10 t_ci = 1'b0; t_x = 1'b0; t_y = 1'b0;
    #10 t_ci = 1'b0; t_x = 1'b0; t_y = 1'b1;
    #10 t_ci = 1'b0; t_x = 1'b1; t_y = 1'b0;
    #10 t_ci = 1'b0; t_x = 1'b1; t_y = 1'b1;

    #10 $dumpoff;
    #10 $finish;
  end

endmodule
