<'

import instruction_s;

-- Simple struct to hold DUV output from monitor.
struct response_s {
  !port   : uint (bits:2);
  !resp   : uint (bits:2);
  !dout   : uint (bits:32);
};

-- Simple scoreboard to check port priorities.
unit scoreboard {
  !expected_packets_1 : list of instruction_s;
  !expected_packets_2 : list of instruction_s;
  !expected_packets_3 : list of instruction_s;
  !expected_packets_4 : list of instruction_s;

  add_packet(p_in : instruction_s) is {
    -- Add packet to the relevant list. This is the easiest way to match input with output,
    -- as the DUV response doesn't really indicate the matching input, other than through
    -- the assumption that input on a port will match the next output on that same port.
    case ins.port {
      1: { expected_packets_1.add(p_in); };
      2: { expected_packets_2.add(p_in); };
      3: { expected_packets_3.add(p_in); };
      4: { expected_packets_4.add(p_in); };
      default: { out("illegal port"); };
    };
  };

  check_packet(p_out : response_s) is {
    --case p_out
  };
'>