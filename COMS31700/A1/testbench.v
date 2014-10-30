`include "reference_model.v"
`include "driver.v"
`include "checker.v"
`uselib lib=calc1_black_box

module calc1_testbench;

   // Main testbench file. This links the driver and checker with the reference model and DUV.
   wire [0:31] out_data [1:4];
   wire [0:1]  out_resp [1:4];
   wire        c_clk;
   wire [0:3]  req_cmd_in  [1:4];
   wire [0:31] req_data_in [1:4];
   wire [1:7]  reset;

   //calc1 DUV(out_data[1], out_data[2], out_data[3], out_data[4], out_resp[1], out_resp[2], out_resp[3], out_resp[4], c_clk, req_cmd_in[1], req_data_in[1], req_cmd_in[2], req_data_in[2], req_cmd_in[3], req_data_in[3], req_cmd_in[4], req_data_in[4], reset);

   calc1_reference CREF(out_data[1], out_data[2], out_data[3], out_data[4], out_resp[1], out_resp[2], out_resp[3], out_resp[4], c_clk, req_cmd_in[1], req_data_in[1], req_cmd_in[2], req_data_in[2], req_cmd_in[3], req_data_in[3], req_cmd_in[4], req_data_in[4], reset);

   calc1_driver DRIVER(c_clk, reset, req_cmd_in[1], req_data_in[1], req_cmd_in[2], req_data_in[2], req_cmd_in[3], req_data_in[3], req_cmd_in[4], req_data_in[4]);

   
   
endmodule // calc1_testbench
