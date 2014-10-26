library verilog;
use verilog.vl_types.all;
entity exdbin_mac is
    port(
        bin_ovfl        : out    vl_logic;
        bin_sum         : out    vl_logic_vector(0 to 63);
        alu_cmd         : in     vl_logic_vector(0 to 3);
        fxu_areg_q      : in     vl_logic_vector(0 to 63);
        local_error_found: in     vl_logic;
        fxu_breg_q      : in     vl_logic_vector(0 to 63)
    );
end exdbin_mac;
