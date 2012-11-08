module fa_test_v3();

  wire t_co,      t_s;
  reg  t_ci, t_x, t_y;

  fa t( .co( t_co ), .s( t_s ), .ci( t_ci ), .x( t_x ), .y( t_y ) );    

  initial begin
        $monitor( "co=%b s=%b ci=%b x=%b y=%b", t_co, t_s, t_ci, t_x, t_y );

    #10 $monitoron;

    #10 t_ci = 1'b0; t_x = 1'b0; t_y = 1'b0;
    #10 t_ci = 1'b0; t_x = 1'b0; t_y = 1'b1;
    #10 t_ci = 1'b0; t_x = 1'b1; t_y = 1'b0;
    #10 t_ci = 1'b0; t_x = 1'b1; t_y = 1'b1;

    #10 $monitoroff;
    #10 $finish;
  end

endmodule
