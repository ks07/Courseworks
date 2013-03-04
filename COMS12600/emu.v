`define PC 15
`define SP 13
//`define 0NIB 4'b0000
//`define 0BYTE 8'b00000000

module emu() ;

   // register file.
   reg [ 31 : 0 ] r [ 0 : 15 ];
   // memory.
   reg [ 31 : 0 ] memory [ 0 : 1023 ];
   // other state and variable declarations
   reg 		  clock;
   

   // Fill in the instruction implementations here.
   // You can use 'tasks' and 'procedures' here to
   // contain your code and allow re-use.
   task movi ;

      input [2:0] rd;

      input [7:0] imm8;

      begin
	 // do the move operation.
	 r[rd] = imm8;
      end
   endtask // movi

   
   // initialise emulator, e.g., memory content
   initial begin
      $readmemh("input.asm", memory);
   end


   // simulate the clock
   always #1 clock = !clock;

   
   // perform a fetch-decode-execute cycle
   always @ ( posedge clock ) begin
      
   end

endmodule