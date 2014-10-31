`include "reference_model.v"
`include "driver.v"
`include "checker.v"
`uselib lib=calc1_black_box

// Main testbench file. This links the driver and checker with the reference model and DUV.
module calc1_testbench;

   // Need separate outputs for the reference and DUV, but they can share the input from the driver.
   wire [0:31] ref_out_data [1:4];
   wire [0:31] duv_out_data [1:4];
   wire [0:1]  ref_out_resp [1:4];
   wire [0:1]  duv_out_resp [1:4];
   wire        c_clk;
   wire [0:3]  req_cmd_in  [1:4];
   wire [0:31] req_data_in [1:4];
   wire [1:7]  reset;
   reg [0:1]   out_prompt [1:4]; // Timing feedback for the reference model.

   integer     i; // Temp loop variable.
   genvar      ii; // Temp genvar.
   
   // Instantiate the DUV.
   calc1 DUV(duv_out_data[1], duv_out_data[2], duv_out_data[3], duv_out_data[4], duv_out_resp[1], duv_out_resp[2], duv_out_resp[3], duv_out_resp[4], c_clk, req_cmd_in[1], req_data_in[1], req_cmd_in[2], req_data_in[2], req_cmd_in[3], req_data_in[3], req_cmd_in[4], req_data_in[4], reset);

   // Instantiate the reference model.
   calc1_reference CREF(ref_out_data[1], ref_out_data[2], ref_out_data[3], ref_out_data[4], ref_out_resp[1], ref_out_resp[2], ref_out_resp[3], ref_out_resp[4], c_clk, req_cmd_in[1], req_data_in[1], req_cmd_in[2], req_data_in[2], req_cmd_in[3], req_data_in[3], req_cmd_in[4], req_data_in[4], reset, out_prompt);

   // Instantiate the driver to drive tests.
   calc1_driver DRIVER(c_clk, reset, req_cmd_in[1], req_data_in[1], req_cmd_in[2], req_data_in[2], req_cmd_in[3], req_data_in[3], req_cmd_in[4], req_data_in[4]);

   // Instantiate the checker to compare the DUV against the reference model.
   calc1_checker CHECKER(c_clk, ref_out_data, ref_out_resp, duv_out_data, duv_out_resp);

   initial
     begin
	for (i = 1; i < 5; i = i + 1)
	  begin
	     out_prompt[i] = 0;
	  end
     end

   generate for (ii = 1; ii < 5; ii = ii + 1)
     begin
	// TODO: This works... but WHY?
	always @ (duv_out_resp[ii])
	  begin
	     // $display("Going out");
	     out_prompt[ii] = duv_out_resp[ii];
	  end
     end
   endgenerate
   
   // TODO: Possible scope for a scoreboard module to help address fairness of scheduling?
   
endmodule // calc1_testbench
