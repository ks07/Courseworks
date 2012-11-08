module fa_test_v4();

  wire t_co,      t_s;
  reg  t_ci, t_x, t_y;

  fa t( .co( t_co ), .s( t_s ), .ci( t_ci ), .x( t_x ), .y( t_y ) );    

  initial begin
        $monitor( "co=%b s=%b ci=%b x=%b y=%b", t_co, t_s, t_ci, t_x, t_y );

    #10 $monitoron;

        if( !$value$plusargs( "ci=%b", t_ci ) ) begin
          $display( "warning: need an unsigned 1-bit binary value for ci" );
          $display( "         i.e., +ci=0 or +ci=1"                       );
        end
        if( !$value$plusargs( "x=%b",  t_x  ) ) begin
          $display( "warning: need an unsigned 1-bit binary value for x"  );
          $display( "         i.e., +x=0  or +x=1"                        );
        end
        if( !$value$plusargs( "y=%b",  t_y  ) ) begin
          $display( "warning: need an unsigned 1-bit binary value for y"  );
          $display( "         i.e., +y=0  or +y=1"                        );
        end

    #10 $monitoroff;
    #10 $finish;
  end

endmodule
