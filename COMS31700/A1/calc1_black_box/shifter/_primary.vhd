library verilog;
use verilog.vl_types.all;
entity shifter is
    port(
        bin_ovfl        : out    vl_logic;
        shift_out       : out    vl_logic_vector(0 to 63);
        shift_cmd       : in     vl_logic_vector(0 to 3);
        shift_places    : in     vl_logic_vector(0 to 63);
        local_error_found: in     vl_logic;
        shift_val       : in     vl_logic_vector(0 to 63)
    );
end shifter;
