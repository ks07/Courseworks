module emu() ;
   // register file
   // PC = 15, LR = 14, SP = 13
   reg [ 31 : 0 ] r [ 0 : 15 ];
   // memory.
   reg [ 31 : 0 ] memory [ 0 : 1023 ];
   // other state and variable declarations
   reg 		  clock;
   // pipeline registers
   reg [ 15 : 0 ] fetched;
   reg [ 15 : 0 ] executing;
   // flags
   reg 		  Z;
   reg 		  C;
   reg 		  N;
   reg 		  V;

   task AddWithCarry;
      input [31:0] x;
      input [31:0] y;
      input 	   carry_in;
      output [31:0] result;
      output 	    carry_out;
      output 	    overflow;
      reg [31:0]    res;
      reg [32:0]    usum;
      reg [32:0]    ssum;
      
      begin	 
	 usum = x + y;
	 usum = usum + carry_in;
	 ssum = $signed(x) + $signed(y);
	 ssum = ssum + carry_in;
	 res = usum[31:0];

	 $display("res %b %b usum", res, usum);
	 
	 if (res == usum) begin
	    carry_out = 0;
	 end else begin
	    carry_out = 1;
	 end
	 
	 if ($signed(res) == ssum) begin
	    overflow = 0;
	 end else begin
	    overflow = 1;
	 end
	 
	 result = res;
      end
   endtask // AddWithCarry
	   
   task addi;
      input [2:0] rdn;
      input [7:0] imm8;
      reg [31:0]  res;
      
      begin
	 AddWithCarry(r[rdn], imm8, 1'b0, res, C, V);

	 N = res[31];
	 setZ(res);
	 
	 r[rdn] = res;
	 $display(" Decoded instruction: addi with rdn=%d, imm8=%d", rdn, imm8);
      end
   endtask // addi

   task addr;
      input [2:0] rd;
      input [2:0] rn;
      input [2:0] rm;
      reg [31:0]  res;
      
      begin
	 AddWithCarry(r[rn], r[rm], 1'b0, res, C, V);

	 N = res[31];
	 setZ(res);
	 
	 r[rd] = res;
	 $display(" Decoded instruction: addr with rd=%d, rn=%d, rm=%d", rd, rn, rm);
      end
   endtask // addr

   task addspi;
      input [2:0] rdn;
      input [7:0] imm8;
      reg [31:0]  imm32;
      reg 	  ign;
      
      begin
	 imm32 = {{22{1'b0}}, imm8, 2'b00};
	 AddWithCarry(r[13], imm32, 0, r[rdn], ign, ign);
	 $display(" Decoded instruction: addspi with rdn=%d, imm8=%d", rdn, imm8);
      end
   endtask // addspi

   task incsp;
      input [6:0] imm7;
      reg 	  ign;
      
      begin
	 AddWithCarry(r[13], imm7, 0, r[13], ign, ign);
	 $display(" Decoded instruction: incsp with imm7=%d", imm7);
      end
   endtask // incsp

   task addpci;
      input [2:0] rd;
      input [7:0] imm8;
      reg [31:0]  imm32;
      
      begin
	 imm32 = {{22{1'b0}}, imm8, 2'b00};
	 r[rd] = r[15] + imm32;
	 $display(" Decoded instruction: addpci with rd=%d, imm8=%d", rd, imm8);
      end
   endtask // addpci

   task subi;
      input [2:0] rdn;
      input [7:0] imm8;
      reg [31:0]  imm32;
      reg [31:0]  res;
      
      begin
	 imm32 = {24'b000000000000000000000000, imm8};
	 AddWithCarry(r[rdn], ~imm32, 1'b1, res, C, V);
	 
	 N = res[31];
	 setZ(res);
	 
	 r[rdn] = res;
	 $display(" Decoded instruction: subi with rdn=%d, imm8=%d", rdn, imm8);
      end
   endtask // subi

   task subr;
      input [2:0] rd;
      input [2:0] rn;
      input [2:0] rm;
      reg [31:0]  res;
      
      begin
	 AddWithCarry(r[rn], ~r[rm], 1, res, C, V);

	 N = res[31];
	 setZ(res);

	 r[rd] = res;
	 $display(" Decoded instruction: subr with rd=%d, rn=%d, rm=%d", rd, rn, rm);
      end
   endtask // subr

   task decsp;
      input [6:0] imm7;
      reg [31:0]  imm32;
      reg [31:0]  res;
      reg 	  ign;
      
      begin
	 imm32 = {{23{1'b0}}, imm7, 2'b00};
	 AddWithCarry(r[13], ~imm32, 1, r[13], ign, ign);
	 $display(" Decoded instruction: decsp with imm7=%d", imm7);
      end
   endtask // decsp

   task mulr;
      input [2:0] rdm;
      input [2:0] rn;
      
      begin
	 r[rdm] = r[rdm] * r[rn];
	 N = r[rdm][31];
	 setZ(r[rdm]);
	 // C, V not updated.
	 $display(" Decoded instruction: mulr with rdm=%d, rn=%d", rdm, rn);
      end
   endtask // mulr

   task andr;
      input [2:0] rdn;
      input [2:0] rm;

      begin
	 r[rdn] = r[rdn] & r[rm];

	 N = r[rdn][31];
	 setZ(r[rdn]);
	 C = 0;
	 // V not updated.
	 $display(" Decoded instruction: andr with rdn=%d, rm=%d", rdn, rm);
      end
   endtask // andr

   task orr;
      input [2:0] rdn;
      input [2:0] rm;

      begin
	 r[rdn] = r[rm] | r[rdn];

	 N = r[rdn][31];
	 setZ(r[rdn]);
	 C = 0;
	 // TODO: Set flags
	 $display(" Decoded instruction: orr with rdn=%d, rm=%d", rdn, rm);
      end
   endtask // orr

   task eorr;
      input [2:0] rdn;
      input [2:0] rm;

      begin
	 r[rdn] = r[rm] ^ r[rdn];

	 N = r[rdn][31];
	 setZ(r[rdn]);
	 C = 0;
	 $display(" Decoded instruction: eorr with rdn=%d, rm=%d", rdn, rm);
      end
   endtask // eorr
   
   task negr;
      input [2:0] rd;
      input [2:0] rn;
      reg [31:0]  res;
      
      begin
	 AddWithCarry(~r[rn], 0, 1, res, C, V);
	 
	 N = res[31];
	 setZ(res);
	 r[rd] = res;
	 $display(" Decoded instruction: negr with rd=%d, rn=%d", rd, rn);
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
	 $display(" Decoded instruction: lsli with rd=%d, rm=%d, imm5=%d", rd, rm, imm5);
      end
   endtask // lsli

   task lslr;
      input [2:0] rdn;
      input [2:0] rm;
      reg [7:0]   shift;

      begin
	 shift = r[rm][7:0];
	 C = r[rdn][32 - shift];
	 r[rdn] = r[rdn] << shift;
	 N = r[rdn][31];
	 setZ(r[rdn]);
	 // V unchanged
	 $display(" Decoded instruction: lslr with rdn=%d, rm=%d", rdn, rm);
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
	 $display(" Decoded instruction: lsri with rd=%d, rm=%d, imm5=%d", rd, rm, imm5);
      end
   endtask // lsri

   task lsrr;
      input [2:0] rdn;
      input [2:0] rm;
      reg [7:0]   shift;
      
      begin
	 shift = r[rm][7:0];
	 C = r[rdn][shift - 1];
	 r[rdn] = r[rdn] >> shift;
	 N = r[rdn][31];
	 setZ(r[rdn]);
	 // V unchanged
	 $display(" Decoded instruction: lsrr with rdn=%d, rm=%d", rdn, rm);
      end
   endtask // lsrr

   task asri;
      input [2:0] rd;
      input [2:0] rm;
      input [4:0] imm5;

      begin
	 // Sign extension handled by icarus, i.e. pad with MSB.
	 r[rd] = $signed(r[rm]) >>> imm5;
	 N = r[rd][31];
	 setZ(r[rd]);
	 C = r[rm][imm5 - 1];
	 $display(" Decoded instruction: asri with rd=%d, rm=%d, imm5=%d", rd, rm, imm5);
      end
   endtask // asri
   
   task movi;
      input [2:0] rd;
      input [7:0] imm8;

      begin
	 // do the move operation.
	 r[rd] = imm8;
	 // Should always be positive, as we only have an 8 bit immediate.
	 N = 0;
	 setZ(r[rd]);
	 // C and V unchanged
	 $display(" Decoded instruction: movi with rd=%d, imm8=%d", rd, imm8);
      end
   endtask // movi

   task movnr;
      input [2:0] rd;
      input [2:0] rm;

      begin
	 r[rd] = ~r[rm];
	 N = r[rd][31];
	 setZ(r[rd]);
	 // Never shifted
	 C = 0;
	 // V unchanged
	 $display(" Decoded instruction: movnr with rd=%d, rm=%d", rd, rm);
      end
   endtask // movnr

   task movrsp;
      input [2:0] rm;

      begin
	 r[15] = r[rm];
	 $display(" Decoded instruction: movrsp with rm=%d", rm);
      end
   endtask // movrsp

   task ldri;
      input [2:0] rt;
      input [2:0] rn;
      input [4:0] imm5;
      integer 	  offset_addr;

      begin
	 offset_addr = r[rn] + imm5;
	 r[rt] = memory[offset_addr];
	 $display(" Decoded instruction: ldri with rt=%d, rn=%d, imm5=%d", rt, rn, imm5);
      end
   endtask // ldri

   task ldrr;
      input [2:0] rt;
      input [2:0] rn;
      input [2:0] rm;
      integer 	  offset_addr;

      begin
	 offset_addr = r[rn] + r[rm];
	 r[rt] = memory[offset_addr];
	 $display(" Decoded instruction: ldrr with rt=%d, rn=%d, rm=%d", rt, rn, rm);
      end
   endtask // ldrr

   task ldrspi;
      input [2:0] rt;
      input [7:0] imm8;
      integer 	  offset_addr;

      begin
	 offset_addr = imm8 * 4;
	 offset_addr = offset_addr + r[13];
	 r[rt] = memory[offset_addr];
	 $display(" Decoded instruction: ldrspi with rt=%d, imm8=%d", rt, imm8);
      end
   endtask // ldrspi

   task ldrpci;
      input [2:0] rd;
      input [7:0] imm8;
      integer 	  addr;

      begin
	 addr = imm8 * 4;
	 addr = addr + r[15];
	 r[rd] = memory[addr];
	 $display(" Decoded instruction: ldrpci with rd=%d, imm8=%d", rd, imm8);
      end
   endtask // ldrpci

   task stri;
      input [2:0] rt;
      input [2:0] rn;
      input [4:0] imm5;
      integer 	  offset_addr;
      
      begin
	 offset_addr = r[rn] + imm5;
	 memory[offset_addr] = r[rt];
	 $display(" Decoded instruction: stri with rt=%d, rn=%d, imm5=%d", rt, rn, imm5);
      end
   endtask // stri

   task strr;
      input [2:0] rt;
      input [2:0] rn;
      input [2:0] rm;
      integer 	  offset_addr;
      
      begin
	 offset_addr = r[rn] + r[rm];
	 memory[offset_addr] = r[rt];
	 $display(" Decoded instruction: strr with rt=%d, rn=%d, rm=%d", rt, rn, rm);
      end
   endtask // strr

   task strspi;
      input [2:0] rt;
      input [7:0] imm8;
      integer 	  offset_addr;
      
      begin
	 offset_addr = imm8 * 4;
	 offset_addr = offset_addr + r[13];
	 memory[offset_addr] = r[rt];
	 $display(" Decoded instruction: strspi with rt=%d, imm8=%d", rt, imm8);
      end
   endtask // strspi
   
   task SPToAddress;
      input [31:0] SP;
      output [9:0] memAdd;

      begin
	 // SP counts in bytes, memory addresses are 4 bytes wide.
	 memAdd = SP >> 2;
      end
   endtask // SPToAddress
   
   task push;
      integer addr;
      
      begin
	 SPToAddress(r[13] - 4, addr);
	 memory[addr] = r[14];
	 r[13] = addr;
	 $display(" Decoded instruction: push");
      end
   endtask // push

   task pop;
      integer addr;
      
      begin
	 SPToAddress(r[13], addr);
	 r[15] = memory[addr];
	 SPToAddress(r[13] + 4, addr);
	 r[13] = addr;
	 $display(" Decoded instruction: pop");
      end
   endtask // pop

   task BranchWritePC;
      input [31:0] addr;

      begin
	 BranchTo({addr[31:1], 1'b0});
      end
   endtask // BranchWritePC

   task BranchTo;
      input [31:0] addr;

      begin
	 r[15] = addr;
	 // Clear the pipeline.
	 fetched = 16'bxxxxxxxxxxxxxxxx;
      end
   endtask // BranchTo
   
   task bu;
      input [10:0] imm11;
      reg signed [31:0]   imm32;
      
      begin
	 imm32 = {{20{imm11[10]}}, imm11, 1'b0};
	 BranchWritePC(r[15] + imm32);
	 $display(" Decoded instruction: bu with imm11=%d", imm11);
      end
   endtask // bu

   task conditionPassed;
      input [3:0] cond;
      output 	  result;
      reg 	  pass;
      
      begin
	 casez (cond)
	   4'b000z: pass = (Z == 1);
	   4'b101z: pass = (N == V);
	   4'b110z: pass = (N == V && Z == 0);
	   default: begin
	      $display("Error: Unsupported condition code: %h", cond);
	      $finish;
	   end
	 endcase // casez (cond)

	 if (cond[0] == 1) begin
	    result = ~pass;
	 end else begin
	    result = pass;
	 end
	 $display("Condition Passed? %b", result);
      end
   endtask // conditionPassed
   
   task b;
      input [3:0] cond;
      input [7:0] imm8;
      reg 	  condT;
      reg signed [31:0] imm32;
      
      begin
	 conditionPassed(cond, condT);

	 if (condT == 1) begin
	    imm32 = {{23{imm8[7]}}, imm8, 1'b0};
	    BranchWritePC(r[15] + imm32);
	 end
	 // Print cond as binary - more useful.
	 $display(" Decoded instruction: b with cond=%b, imm8=%d", cond, imm8);
      end
   endtask // b

   /*task bl;
      signed input [9:0] imm10;

      begin

      end
   endtask // bl

   task bl2;
      input [10:0] imm11;

      begin

      end
   endtask // bl2*/

   task bl_32;
      input [9:0]  imm10;
      input [10:0] imm11;
      integer 	   imm32;
      
      begin
	 r[14] = r[15];
	 r[14][0] = 1;
	 //TODO: branchwritepc
	 //TODO: sign extensions
	 imm32 = {imm10, imm11, 1'b0};
	 r[15] = r[15] + imm32;
	 $display(" Decoded instruction: bl(2) with imm10=%d, imm11=%d", imm10, imm11);
      end
   endtask // bl_32
   
   task br;
      input [2:0] rm;
      reg [31:0]  addr;
      
      begin
	 //branch to reg
	 addr = r[rm];
	 addr[0] = 1'b0;
	 BranchTo(r[rm]);
	 $display(" Decoded instruction: br with rm=%d", rm);
      end
   endtask // br

   task svc;
      input [7:0] imm8;

      begin
	 $display(" Decoded instruction: svc with imm8=%d", imm8);
	 
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
	 $display(" r0=%h,  r1=%h,  r2=%h,  r3=%h", r[0], r[1], r[2], r[3]);
	 $display(" r4=%h,  r5=%h,  r6=%h,  r7=%h", r[4], r[5], r[6], r[7]);
	 $display(" r8=%h,  r9=%h, r10=%h, r11=%h", r[8], r[9], r[10], r[11]);
	 $display("r12=%h, r13=%h, r14=%h, r15=%h", r[12], r[13], r[14], r[15]);
      end
   endtask // printRegisters

   task fetch;
      reg [15:0] addr;
      
      begin
	 executing = fetched;
	 
	 // PC counts in bytes, each instruction is 2 bytes, each memory location is 2 instructions.
	 // If divisable by 4, then MSB, else LSB. Increment by 2 each step.
	 addr = r[15] >> 2;
	 
	 if (r[15][1] == 0) begin
	    // Use LSBs.
	    fetched = memory[addr][15:0];
	 end else begin
	    // MSBs.
	    fetched = memory[addr][31:16];
	 end

	 // Increment PC
	 r[15] = r[15] + 2;
      end
   endtask // fetch
   
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
//	   16'b111100zzzzzzzzzz: bl(in[9:0]);
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
//	   16'b11111zzzzzzzzzzz: bl2(in[10:0]);
	   //  15   10 7 5  2 0
	   16'b1101zzzzzzzzzzzz: b(in[11:8], in[7:0]);
	   default: begin
	      $display("Unrecognised instruction: %h", in);
	      $finish;
	   end
	 endcase // casez (in)
      end
   endtask // decode
   
   task printTrace;
      begin
	 $display(" pc=%h,  Z = %b, N = %b, C = %b, V = %b", r[15], Z, N, C, V);
	 printRegisters();
      end
   endtask // printTrace
   
   // initialise emulator, e.g., memory content
   initial begin
      $readmemh("example.emu", memory);
      
      clock = 0;
      r[15] = 0;
      Z = 0;
      N = 0;
      C = 0;
      V = 0;
   end

   // simulate the clock
   always #1 clock = !clock;

   // perform a fetch-decode-execute cycle
   always @ ( posedge clock ) begin
      if (fetched === 16'bxxxxxxxxxxxxxxxx) begin
	 $display("Pipeline empty, fetching.");
	 fetch();
      end else begin	 
	 $display(" Executing instruction @ %h: '%b'", r[15] - 2, fetched);
	 fetch();
	 decode(executing);
	 printTrace();
      end
      
   end

endmodule