`define PC 15
`define LR 14
`define SP 13

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
   reg [ 32 : 0 ] temp;
   

   // Fill in the instruction implementations here.
   // You can use 'tasks' and 'procedures' here to
   // contain your code and allow re-use.
   task addi;
      input [2:0] rdn;
      input [7:0] imm8;

      begin
	 temp = r[rdn] + imm8;

	 if (temp[32] == 1 && r[rdn][31] == 1) begin
	    C = 1;
	 end else begin
	    C = 0;
	 end

	 r[rdn] = temp;
      end
   endtask // addi

   task addr;
      input [2:0] rd;
      input [2:0] rn;
      input [2:0] rm;

      begin
	 r[rd] = r[rn] + r[rm];
      end
   endtask // addr

   task addspi;
      input [2:0] rdn;
      input [7:0] imm8;

      begin
	 r[rdn] = r[13] + imm8;
	 
      end
   endtask // addspi

   task incsp;
      input [6:0] imm7;

      begin
	 r[13] = r[13] + imm7;
	 
      end
   endtask // incsp

   task addpci;
      input [2:0] rd;
      input [7:0] imm8;

      begin
	 r[rd] = r[15] + imm8;
	 
      end
   endtask // addpci

   task subi;
      input [2:0] rdn;
      input [7:0] imm8;

      begin
	 r[rdn] = r[rdn] - imm8;
      end
   endtask // subi

   task subr;
      input [2:0] rd;
      input [2:0] rn;
      input [2:0] rm;

      begin
	 r[rd] = r[rn] - r[rm];
	 
      end
   endtask // subr

   task decsp;
      input [6:0] imm7;

      begin
	 r[13] = r[13] - imm7;
	 
      end
   endtask // decsp

   task mulr;
      input [2:0] rdm;
      input [2:0] rn;

      begin
	 r[rdm] = r[rdm] * r[rn];
      end
   endtask // mulr

   task andr;
      input [2:0] rdn;
      input [2:0] rm;

      begin
	 r[rdn] = r[rdn] & r[rm];
	 
      end
   endtask // andr

   task orr;
      input [2:0] rdn;
      input [2:0] rm;

      begin
	 r[rdn] = r[rm] | r[rdn];
	 
      end
   endtask // orr

   task eorr;
      input [2:0] rdn;
      input [2:0] rm;

      begin
	 r[rdn] = r[rm] ^ r[rdn];
	 
      end
   endtask // eorr

   task negr;
      input [2:0] rd;
      input [2:0] rn;

      begin
	 r[rd] = 0 - r[rn];

	 N = r[rd][31];
	 setZ(r[rd]);
	 if (r[rd][31] == r[rn][31]) begin
	    V = 1;
	 end else begin
	    V = 0;
	 end
	 C = 0;
      end
   endtask // negr

   task lsli;
      input [2:0] rd;
      input [2:0] rm;
      input [4:0] imm5;

      begin
	 r[rd] = r[rm] << imm5;
	 N = r[rd][31];
	 setZ(r[rd]);
	 C = r[rm][32 - imm5];
	 // V unchanged
      end
   endtask // lsli

   task lslr;
      input [2:0] rdn;
      input [2:0] rm;
      integer 	  shift;

      begin
	 shift = r[rm][7:0];
	 // TODO: C, shift when 0
	 C = r[rdn][32 - shift];
	 r[rdn] = r[rdn] << shift;
	 N = r[rdn][31];
	 setZ(r[rdn]);
	 // V unchanged
      end
   endtask // lslr

   task lsri;
      input [2:0] rd;
      input [2:0] rm;
      input [4:0] imm5;

      begin
         r[rd] = r[rm] >> imm5;
	 N = r[rd][31];
	 setZ(r[rd]);
	 C = r[rm][imm5 - 1];
	 // V unchanged
      end
   endtask // lsri

   task lsrr;
      input [2:0] rdn;
      input [2:0] rm;
      integer 	  shift;
      
      begin
	 shift = r[rm][7:0];
	 // TODO: C, shift when 0
	 C = r[rdn][shift - 1];
	 r[rdn] = r[rdn] >> shift;
	 N = r[rdn][31];
	 setZ(r[rdn]);
	 // V unchanged
      end
   endtask // lsrr

   task asri;
      input [2:0] rd;
      input [2:0] rm;
      input [4:0] imm5;
      integer 	  toShift;

      begin
	 toShift = r[rm];
	 
	 r[rd] = toShift >>> imm5;
	 N = r[rd][31];
	 setZ(r[rd]);
	 // TODO: Set C
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
      input [2:0] rd;
      input [2:0] rm;

      begin
	 r[rd] = ~r[rm];
      end
   endtask // movnr

   task movrsp;
      input [2:0] rm;

      begin
	 r[15] = r[rm];
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
      input [7:0] imm8;

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
      input [3:0] cond;
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
   endtask // br

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

   task setZ;
      input [31:0] num;

      begin
	 if (num == 0) begin
	    Z = 1;
	 end else begin
	    Z = 0;
	 end
      end
   endtask // setZ

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

   task decode;
      input [15:0] in;

      begin
	 casez (in)
	   //  15   10 7 5  2 0
	   16'b1011010100000000: push();
	   16'b1011110100000000: pop();
	   16'b0100011010zzz101: movrsp(in[5:3]);
	   16'b0100011100zzz000: br(in[5:3]);
	   16'b0100000000zzzzzz: andr(in[2:0], in[5:3]);
	   //  15   10 7 5  2 0
	   16'b0100000001zzzzzz: eorr(in[2:0], in[5:3]);
	   16'b0100000010zzzzzz: lslr(in[2:0], in[5:3]);
	   16'b0100000011zzzzzz: lsrr(in[2:0], in[5:3]);
	   16'b0100001001zzzzzz: negr(in[2:0], in[5:3]);
	   16'b0100001100zzzzzz: orr(in[2:0], in[5:3]);
	   //  15   10 7 5  2 0
	   16'b0100001101zzzzzz: mulr(in[2:0], in[5:3]);
	   16'b0100001111zzzzzz: movnr(in[2:0], in[5:3]);
	   16'b101100000zzzzzzz: incsp(in[6:0]);
	   16'b101100001zzzzzzz: decsp(in[6:0]);
	   16'b11011111zzzzzzzz: svc(in[7:0]);
	   //  15   10 7 5  2 0
	   16'b0101000zzzzzzzzz: strr(in[2:0], in[5:3], in[8:6]);
	   16'b0001100zzzzzzzzz: addr(in[2:0], in[5:3], in[8:6]);
	   16'b0001101zzzzzzzzz: subr(in[2:0], in[5:3], in[8:6]);
	   16'b0101100zzzzzzzzz: ldrr(in[2:0], in[5:3], in[8:6]);
	   16'b111100zzzzzzzzzz: bl(in[9:0]);
	   //  15   10 7 5  2 0
	   16'b00000zzzzzzzzzzz: lsli(in[2:0], in[5:3], in[10:6]);
	   16'b00001zzzzzzzzzzz: lsri(in[2:0], in[5:3], in[10:6]);
	   16'b00010zzzzzzzzzzz: asri(in[2:0], in[5:3], in[10:6]);
	   16'b00100zzzzzzzzzzz: movi(in[10:8], in[7:0]);
	   16'b00110zzzzzzzzzzz: addi(in[10:8], in[7:0]);
	   //  15   10 7 5  2 0
	   16'b00111zzzzzzzzzzz: subi(in[10:8], in[7:0]);
	   16'b01001zzzzzzzzzzz: ldrpci(in[10:8], in[7:0]);
	   16'b01100zzzzzzzzzzz: stri(in[2:0], in[5:3], in[10:6]);
	   16'b01101zzzzzzzzzzz: ldri(in[2:0], in[5:3], in[10:6]);
	   16'b10010zzzzzzzzzzz: strspi(in[10:8], in[7:0]);
	   //  15   10 7 5  2 0
	   16'b10011zzzzzzzzzzz: ldrspi(in[10:8], in[7:0]);
	   16'b10100zzzzzzzzzzz: addpci(in[10:8], in[7:0]);
	   16'b10101zzzzzzzzzzz: addspi(in[10:8], in[7:0]);
	   16'b11100zzzzzzzzzzz: bu(in[10:0]);
	   16'b11111zzzzzzzzzzz: bl2(in[10:0]);
	   //  15   10 7 5  2 0
	   16'b1101zzzzzzzzzzzz: b(in[11:8], in[7:0]);
	   default: begin
	      $display("Unrecognised instruction: %h", in);
	      $finish;
	   end
	 endcase // casez (in)
      end
   endtask // decode
   
	   
   
   // initialise emulator, e.g., memory content
   initial begin
      /*r[0] = 10;
      r[1] = 1;
      r[2] = 2;
      r[3] = 3;
      r[4] = 4;
      addr(0, 4, 3);
      
      $display("%d", r[0]);*/
      clock = 0;

      printRegisters();
      decode(16'b0010000000000010);
      printRegisters();
      decode(16'b0011000000000001);
      printRegisters();
      
      
      //$readmemh("input.asm", memory);
   end


   // simulate the clock
   always #1 clock = !clock;

   // perform a fetch-decode-execute cycle
   always @ ( posedge clock ) begin
      r[0] = r[0] + 1;

      $finish;
      
   end

endmodule