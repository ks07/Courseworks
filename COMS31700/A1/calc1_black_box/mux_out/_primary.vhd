library verilog;
use verilog.vl_types.all;
entity mux_out is
    port(
        req_data        : out    vl_logic_vector(0 to 31);
        req_resp        : out    vl_logic_vector(0 to 1);
        req_data1       : in     vl_logic_vector(0 to 31);
        req_data2       : in     vl_logic_vector(0 to 31);
        req_resp1       : in     vl_logic_vector(0 to 1);
        req_resp2       : in     vl_logic_vector(0 to 1)
    );
end mux_out;
