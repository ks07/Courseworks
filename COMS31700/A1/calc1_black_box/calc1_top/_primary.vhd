library verilog;
use verilog.vl_types.all;
entity calc1_top is
    port(
        out_data1       : out    vl_logic_vector(0 to 31);
        out_data2       : out    vl_logic_vector(0 to 31);
        out_data3       : out    vl_logic_vector(0 to 31);
        out_data4       : out    vl_logic_vector(0 to 31);
        out_resp1       : out    vl_logic_vector(0 to 1);
        out_resp2       : out    vl_logic_vector(0 to 1);
        out_resp3       : out    vl_logic_vector(0 to 1);
        out_resp4       : out    vl_logic_vector(0 to 1);
        scan_out        : out    vl_logic;
        a_clk           : in     vl_logic;
        b_clk           : in     vl_logic;
        c_clk           : in     vl_logic;
        error_found     : in     vl_logic_vector(0 to 3);
        req1_cmd_in     : in     vl_logic_vector(0 to 3);
        req1_data_in    : in     vl_logic_vector(0 to 31);
        req2_cmd_in     : in     vl_logic_vector(0 to 3);
        req2_data_in    : in     vl_logic_vector(0 to 31);
        req3_cmd_in     : in     vl_logic_vector(0 to 3);
        req3_data_in    : in     vl_logic_vector(0 to 31);
        req4_cmd_in     : in     vl_logic_vector(0 to 3);
        req4_data_in    : in     vl_logic_vector(0 to 31);
        reset           : in     vl_logic_vector(1 to 7);
        scan_in         : in     vl_logic
    );
end calc1_top;
