<'

-- Simple scoreboard-eque unit to check port priorities.
-- A traditional scoreboard will not be useful here, as there can only be 4 commands
-- in the DUV at a time (one per port), and we can only drive an input after that port
-- has given a response. Thus, we will simply hold a counter for the number of commands
-- processed per port, and give an indication of their average response time.
unit scoreboard_u {

  -- Use two monitors to get info from DUV.
--  in_mon : monitor_u is instance;
--  keep in_mon.scbd == this;

  -- Use 5 length lists so we can index as 1..4
  !drive_count[5] : list of uint;
  !resp_count[5]  : list of uint;
  !total_time[5]  : list of time;
  !drive_time[5]  : list of time;

  add_packet(port : uint) is {
    -- Use sys.time to get the current sim time.
--    out("PACKET DRIVEN ", port);
    drive_time[port] = sys.time;
    drive_count[port] = drive_count[port] + 1;
  };

  check_packet(port : uint) is {
    var check_time : time;
    check_time = sys.time;

    -- Update the total time spent on this port.
    total_time[port] = total_time[port] + check_time - drive_time[port];
    resp_count[port] = resp_count[port] + 1;
  };

  // Reset should clear the scoreboard.
  reset() is {
    for p from 0 to 4 do {
      drive_count[p] = 0;
      resp_count[p] = 0;
      total_time[p] = 0;
      drive_time[p] = 0;
    };
  };

  quit() is first {
    out("Scoreboard finalised.");
    out("Commands processed per port:");
    for p from 1 to 4 do {
      if resp_count[p] != drive_count[p] {
        dut_error("Response count doesn't match drive count on port ", p, " ", resp_count[p], " ", drive_count[p]);
      };
      out(p, " ", resp_count[p]);
    };
  };
};

-- Add a scoreboard to the global sys space.
extend sys {

   scoreboard : scoreboard_u is instance;

};

'>
