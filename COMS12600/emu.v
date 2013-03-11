`define PC 15
`define LR 14
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
   // flags
   reg 		  Z;
   reg 		  C;
   reg 		  N;
   reg 		  V;
   

   // Fill in the instruction implementations here.
   // You can use 'tasks' and 'procedures' here to
   // contain your code and allow re-use.
   task addi;
      input [3:0] rdn;
      input [7:0] imm8;

      begin

      end
   endtask // addi

   task addr;
      input [3:0] rd;
      input [3:0] rn;
      input [3:0] rm;

      begin

      end
   endtask // addr

   task addspi;
      input [3:0] rdn;
      input [7:0] imm8;

      begin

      end
   endtask; // addspi

   task incsp;
      input [6:0] imm7;

      begin

      end
   endtask // incsp

   task addpci;
      input [3:0] rd;
      input [7:0] imm8;

      begin

      end
   endtask // addpci

   task subi;
      input [3:0] rdn;
      input [7:0] imm8;

      begin

      end
   endtask // subi

   task subr;
      input [3:0] rd;
      input [3:0] rn;
      input [3:0] rm;

      begin

      end
   endtask // subr

   task decsp;
      input [6:0] imm7;

      begin

      end
   endtask // decsp

   task mulr;
      input [3:0] rdm;
      input [3:0] rn;

      begin

      end
   endtask // mulr

   task andr;
      input [3:0] rdn;
      input [3:0] rm;

      begin

      end
   endtask // andr

   task orr;
      input [3:0] rdn;
      input [3:0] rm;

      begin

      end
   endtask // orr

   task eorr;
      input [3:0] rdn;
      input [3:0] rm;

      begin

      end
   endtask // eorr

   task negr;
      input [3:0] rd;
      input [3:0] rn;

      begin

      end
   endtask // negr

   task lsli;
      input [3:0] rd;
      input [3:0] rm;
      input [4:0] imm5;

      begin

      end
   endtask // lsli

   task lslr;
      input [3:0] rdn;
      input [3:0] rm;

      begin

      end
   endtask // lslr

   task lsri;
      input [3:0] rd;
      input [3:0] rm;
      input [4:0] imm5;

      begin

      end
   endtask // lsri

   task lsrr;
      input [3:0] rdn;
      input [3:0] rm;
      
      begin

      end
   endtask // lsrr

   task asri;
      input [3:0] rd;
      input [3:0] rm;

      begin

      end
   endtask // asri
   
   task movi;
      input [2:0] rd;
      input [7:0] imm8;

      begin
	 // do the move operation.
	 r[rd] = imm8;
      end
   endtask // movi

   task movnr;
      input [3:0] rd;
      input [3:0] rm;

      begin

      end
   endtask // movnr

   task movrsp;
      input [3:0] rm;

      begin

      end
   endtask // movrsp

   task ldri;
      input [3:0] rt;
      input [3:0] rn;
      input [4:0] imm5;

      begin

      end
   endtask // ldri

   task ldrr;
      input [3:0] rt;
      input [3:0] rn;
      input [3:0] rm;

      begin

      end
   endtask // ldrr

   task ldrspi;
      input [3:0] rt;
      input [7:0] imm8;

      begin

      end
   endtask // ldrspi

   task ldrpci;
      input [3:0] rd;
      input [7:0] imm8;

      begin

      end
   endtask // ldrpci

   task stri;
      input [3:0] rt;
      input [3:0] rn;
      input [4:0] imm5;

      begin

      end
   endtask // stri

   task strr;
      input [3:0] rt;
      input [3:0] rn;
      input [3:0] rm;

      begin

      end
   endtask // strr

   task strspi;
      input [3:0] rt;
      input [3:0] rn;
      input [3:0] rm;

      begin

      end
   endtask // strspi

   task push;
      begin

      end
   endtask // push

   task pop;
      begin

      end
   endtask // pop

   task bu;
      input [10:0] imm11;

      begin

      end
   endtask // bu

   task b;
      input [10:0] imm11;

      begin

      end
   endtask // b

   task bl;
      input [9:0] imm10;

      begin

      end
   endtask // bl

   task bl2;
      input [10:0] imm11;

      begin

      end
   endtask // bl2

   task br;
      input [3:0] rm;

      begin

      end
   endtask; // br

   task svc;
      input [7:0] imm8;

      begin
	 if (imm8 < 8) begin
	    $display (r[imm8]);
	 end else if (imm8 == 16) begin
	    printRegisters();
	 end else if (imm8 == 100) begin
	    $display("Simulation stopped, SVC 100");
	    $finish;
	 end else if (imm8 == 101) begin
	    dumpMemory();
	 end
      end
   endtask // svc

   //integer addr;
   
   task dumpMemory ;
      integer addr;
      
      begin
	 for (addr = 0; addr < 1023; addr = addr + 4) begin
	    $display("%h:  %h", addr, memory[addr]);
	 end
      end
   endtask // dumpMemory
   
   task printRegisters ;
      begin
	 $display("r0=%h, r1=%h, r2=%h, r3=%h", r[0], r[1], r[2], r[3]);
	 $display("r4=%h, r5=%h, r6=%h, r7=%h", r[4], r[5], r[6], r[7]);
	 $display("r8=%h, r9=%h, r10=%h, r11=%h", r[8], r[9], r[10], r[11]);
	 $display("r12=%h, r13=%h, r14=%h, r15=%h", r[12], r[13], r[14], r[15]);
      end
   endtask // printRegisters
   
   
   // initialise emulator, e.g., memory content
   initial begin
      $readmemh("input.asm", memory);
   end


   // simulate the clock
   always #1 clock = !clock;

   // perform a fetch-decode-execute cycle
   always @ ( posedge clock ) begin
      r[0] = r[0] + 1;

      $finish;
      
   end

endmodule