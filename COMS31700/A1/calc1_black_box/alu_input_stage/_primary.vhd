library verilog;
use verilog.vl_types.all;
entity alu_input_stage is
    port(
        alu_data1       : out    vl_logic_vector(0 to 63);
        alu_data2       : out    vl_logic_vector(0 to 63);
        hold1_data1     : in     vl_logic_vector(0 to 31);
        hold1_data2     : in     vl_logic_vector(0 to 31);
        hold2_data1     : in     vl_logic_vector(0 to 31);
        hold2_data2     : in     vl_logic_vector(0 to 31);
        hold3_data1     : in     vl_logic_vector(0 to 31);
        hold3_data2     : in     vl_logic_vector(0 to 31);
        hold4_data1     : in     vl_logic_vector(0 to 31);
        hold4_data2     : in     vl_logic_vector(0 to 31);
        prio_alu_in_cmd : in     vl_logic_vector(0 to 3);
        prio_alu_in_req_id: in     vl_logic_vector(0 to 1)
    );
end alu_input_stage;
