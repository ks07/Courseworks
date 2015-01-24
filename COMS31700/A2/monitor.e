<'

-- Monitor to attach to inputs
unit monitor_u {
  clk_p : in simple_port of bit is instance; // read by sn
  keep clk_p.hdl_path() == "~/calc1_sn/c_clk";
  reset_p : in simple_port of uint(bits:7) is instance; // read by sn
  keep reset_p.hdl_path() == "~/calc1_sn/reset";
  req1_cmd_in_p : in simple_port of uint(bits:4) is instance; // read by sn
  keep req1_cmd_in_p.hdl_path() == "~/calc1_sn/req1_cmd_in";
  req2_cmd_in_p : in simple_port of uint(bits:4) is instance; // read by sn
  keep req2_cmd_in_p.hdl_path() == "~/calc1_sn/req2_cmd_in";
  req3_cmd_in_p : in simple_port of uint(bits:4) is instance; // read by sn
  keep req3_cmd_in_p.hdl_path() == "~/calc1_sn/req3_cmd_in";
  req4_cmd_in_p : in simple_port of uint(bits:4) is instance; // read by sn
  keep req4_cmd_in_p.hdl_path() == "~/calc1_sn/req4_cmd_in";
  out_resp1_p : in simple_port of uint(bits:2) is instance; // read by sn
  keep out_resp1_p.hdl_path() == "~/calc1_sn/out_resp1";
  out_resp2_p : in simple_port of uint(bits:2) is instance; // read by sn
  keep out_resp2_p.hdl_path() == "~/calc1_sn/out_resp2";
  out_resp3_p : in simple_port of uint(bits:2) is instance; // read by sn
  keep out_resp3_p.hdl_path() == "~/calc1_sn/out_resp3";
  out_resp4_p : in simple_port of uint(bits:2) is instance; // read by sn
  keep out_resp4_p.hdl_path() == "~/calc1_sn/out_resp4";

  event clk is fall(clk_p$)@sim;
  event reset is change(reset_p$)@clk;
  event drive1 is change(req1_cmd_in_p$)@clk;
  event drive2 is change(req2_cmd_in_p$)@clk;
  event drive3 is change(req3_cmd_in_p$)@clk;
  event drive4 is change(req4_cmd_in_p$)@clk;
  event resp1 is change(out_resp1_p$)@clk;
  event resp2 is change(out_resp2_p$)@clk;
  event resp3 is change(out_resp3_p$)@clk;
  event resp4 is change(out_resp4_p$)@clk;

  scbd : scoreboard_u;
  keep scbd == sys.scoreboard;

  run() is also {
    start reset_driven();

    start command_driven_1();
    start command_driven_2();
    start command_driven_3();
    start command_driven_4();

    start response_driven_1();
    start response_driven_2();
    start response_driven_3();
    start response_driven_4();
  };

  reset_driven() @reset is {
    while TRUE {
      scbd.reset();
      wait @reset;
    };
  };

  command_driven_1() @drive1 is {
    while TRUE {
      scbd.add_packet(1);
      wait @drive1;
    };
  };
  command_driven_2() @drive2 is {
    while TRUE {
      scbd.add_packet(2);
      wait @drive2;
    };
  };
  command_driven_3() @drive3 is {
    while TRUE {
      scbd.add_packet(3);
      wait @drive3;
    };
  };
  command_driven_4() @drive4 is {
    while TRUE {
      scbd.add_packet(4);
      wait @drive4;
    };
  };

  response_driven_1() @resp1 is {
    while TRUE {
      scbd.check_packet(1);
      wait @resp1;
    };
  };
  response_driven_2() @resp2 is {
    while TRUE {
      scbd.check_packet(2);
      wait @resp2;
    };
  };
  response_driven_3() @resp3 is {
    while TRUE {
      scbd.check_packet(3);
      wait @resp3;
    };
  };
  response_driven_4() @resp4 is {
    while TRUE {
      scbd.check_packet(4);
      wait @resp4;
    };
  };

};

extend sys {

  // This is a bit messy... but e doesn't have any instance parameterisation...
  monitor : monitor_u is instance;

};

'>
