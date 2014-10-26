library verilog;
use verilog.vl_types.all;
entity priority is
    port(
        prio_alu1_in_cmd: out    vl_logic_vector(0 to 3);
        prio_alu1_in_req_id: out    vl_logic_vector(0 to 1);
        prio_alu1_out_req_id: out    vl_logic_vector(0 to 1);
        prio_alu1_out_vld: out    vl_logic;
        prio_alu2_in_cmd: out    vl_logic_vector(0 to 3);
        prio_alu2_in_req_id: out    vl_logic_vector(0 to 1);
        prio_alu2_out_req_id: out    vl_logic_vector(0 to 1);
        prio_alu2_out_vld: out    vl_logic;
        scan_out        : out    vl_logic;
        a_clk           : in     vl_logic;
        b_clk           : in     vl_logic;
        c_clk           : in     vl_logic;
        hold1_prio_req  : in     vl_logic_vector(0 to 3);
        hold2_prio_req  : in     vl_logic_vector(0 to 3);
        hold3_prio_req  : in     vl_logic_vector(0 to 3);
        hold4_prio_req  : in     vl_logic_vector(0 to 3);
        local_error_found: in     vl_logic;
        reset           : in     vl_logic_vector(1 to 7);
        scan_in         : in     vl_logic
    );
end priority;
