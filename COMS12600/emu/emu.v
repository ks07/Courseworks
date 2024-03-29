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
   // simulator loop count
   integer 	  blankFetch;
   
   task AddWithCarry;
      input [31:0]  x_in;
      input [31:0]  y_in;
      input 	    c_in;
      output [31:0] res;
      output 	    carry_out;
      output 	    overflow;
      // Verilog makes me do strange things.
      reg [32:0]    x;
      reg [32:0]    y;
      reg [32:0]    carry_in;
      reg [32:0]    usum;
      reg signed [32:0] ssum;
      
      begin
	 x = {x_in[31], x_in};
	 y = {y_in[31], y_in};
	 carry_in = {{32{1'b0}}, c_in};
	 
	 usum = x + y + carry_in;
	 ssum = $signed(x) + $signed(y) + carry_in;
	 
	 res = usum[31:0];
	 
	 if (res == usum) begin
	    carry_out = 1'b0;
	 end else begin
	    carry_out = 1'b1;
	 end
	 
	 if ($signed(res) == ssum) begin
	    overflow = 0;
	 end else begin
	    overflow = 1;
	 end
      end
   endtask // AddWithCarry
	   
   task addi;
      input [2:0] rdn;
      input [7:0] imm8;
      reg [31:0]  res;
      
      begin
	 $display(" Decoded instruction: addi with rdn=%d, imm8=%d", rdn, imm8);
	 AddWithCarry(r[rdn], imm8, 1'b0, res, C, V);

	 N = res[31];
	 setZ(res);
	 
	 r[rdn] = res;
      end
   endtask // addi

   task addr;
      input [2:0] rd;
      input [2:0] rn;
      input [2:0] rm;
      reg [31:0]  res;
      
      begin
	 $display(" Decoded instruction: addr with rd=%d, rn=%d, rm=%d", rd, rn, rm);
	 AddWithCarry(r[rn], r[rm], 1'b0, res, C, V);

	 N = res[31];
	 setZ(res);
	 
	 r[rd] = res;
      end
   endtask // addr

   task addspi;
      input [2:0] rdn;
      input [7:0] imm8;
      reg [31:0]  imm32;
      reg 	  ign;
      
      begin
	 $display(" Decoded instruction: addspi with rdn=%d, imm8=%d", rdn, imm8);
	 imm32 = {{22{1'b0}}, imm8, 2'b00};
	 AddWithCarry(r[13], imm32, 0, r[rdn], ign, ign);
      end
   endtask // addspi

   task incsp;
      input [6:0] imm7;
      reg 	  ign;
      
      begin
	 $display(" Decoded instruction: incsp with imm7=%d", imm7);
	 AddWithCarry(r[13], imm7, 0, r[13], ign, ign);
      end
   endtask // incsp

   task addpci;
      input [2:0] rd;
      input [7:0] imm8;
      reg [31:0]  imm32;
      
      begin
	 $display(" Decoded instruction: addpci with rd=%d, imm8=%d", rd, imm8);
	 imm32 = {{22{1'b0}}, imm8, 2'b00};
	 r[rd] = r[15] + imm32;
      end
   endtask // addpci

   task subi;
      input [2:0] rdn;
      input [7:0] imm8;
      reg [31:0]  imm32;
      reg [31:0]  res;
      
      begin
	 $display(" Decoded instruction: subi with rdn=%d, imm8=%d", rdn, imm8);
	 imm32 = {24'b000000000000000000000000, imm8};
	 AddWithCarry(r[rdn], ~imm32, 1'b1, res, C, V);
	 
	 N = res[31];
	 setZ(res);
	 
	 r[rdn] = res;
      end
   endtask // subi

   task subr;
      input [2:0] rd;
      input [2:0] rn;
      input [2:0] rm;
      reg [31:0]  res;
      
      begin
	 $display(" Decoded instruction: subr with rd=%d, rn=%d, rm=%d", rd, rn, rm);
	 AddWithCarry(r[rn], ~r[rm], 1'b1, res, C, V);

	 N = res[31];
	 setZ(res);

	 r[rd] = res;
      end
   endtask // subr

   task decsp;
      input [6:0] imm7;
      reg [31:0]  imm32;
      reg [31:0]  res;
      reg 	  ign;
      
      begin
	 $display(" Decoded instruction: decsp with imm7=%d", imm7);
	 imm32 = {{23{1'b0}}, imm7, 2'b00};
	 AddWithCarry(r[13], ~imm32, 1, r[13], ign, ign);
      end
   endtask // decsp

   task mulr;
      input [2:0] rdm;
      input [2:0] rn;
      
      begin
	 $display(" Decoded instruction: mulr with rdm=%d, rn=%d", rdm, rn);
	 r[rdm] = r[rdm] * r[rn];
	 N = r[rdm][31];
	 setZ(r[rdm]);
	 // C, V not updated.
      end
   endtask // mulr

   task andr;
      input [2:0] rdn;
      input [2:0] rm;

      begin
	 $display(" Decoded instruction: andr with rdn=%d, rm=%d", rdn, rm);
	 r[rdn] = r[rdn] & r[rm];

	 N = r[rdn][31];
	 setZ(r[rdn]);
	 C = 0;
	 // V not updated.
      end
   endtask // andr

   task orr;
      input [2:0] rdn;
      input [2:0] rm;

      begin
	 $display(" Decoded instruction: orr with rdn=%d, rm=%d", rdn, rm);
	 r[rdn] = r[rm] | r[rdn];

	 N = r[rdn][31];
	 setZ(r[rdn]);
	 C = 0;
      end
   endtask // orr

   task eorr;
      input [2:0] rdn;
      input [2:0] rm;

      begin
	 $display(" Decoded instruction: eorr with rdn=%d, rm=%d", rdn, rm);
	 r[rdn] = r[rm] ^ r[rdn];

	 N = r[rdn][31];
	 setZ(r[rdn]);
	 C = 0;
      end
   endtask // eorr
   
   task negr;
      input [2:0] rd;
      input [2:0] rn;
      reg [31:0]  res;
      
      begin
	 $display(" Decoded instruction: negr with rd=%d, rn=%d", rd, rn);
	 AddWithCarry(~r[rn], 0, 1, res, C, V);
	 
	 N = res[31];
	 setZ(res);
	 r[rd] = res;
      end
   endtask // negr

   task lsli;
      input [2:0] rd;
      input [2:0] rm;
      input [4:0] imm5;

      begin
	 $display(" Decoded instruction: lsli with rd=%d, rm=%d, imm5=%d", rd, rm, imm5);
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
      reg [7:0]   shift;

      begin
	 $display(" Decoded instruction: lslr with rdn=%d, rm=%d", rdn, rm);
	 shift = r[rm][7:0];
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
	 $display(" Decoded instruction: lsri with rd=%d, rm=%d, imm5=%d", rd, rm, imm5);
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
      reg [7:0]   shift;
      
      begin
	 $display(" Decoded instruction: lsrr with rdn=%d, rm=%d", rdn, rm);
	 shift = r[rm][7:0];
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

      begin
	 $display(" Decoded instruction: asri with rd=%d, rm=%d, imm5=%d", rd, rm, imm5);
	 // Sign extension handled by icarus, i.e. pad with MSB.
	 r[rd] = $signed(r[rm]) >>> imm5;
	 N = r[rd][31];
	 setZ(r[rd]);
	 C = r[rm][imm5 - 1];
      end
   endtask // asri
   
   task movi;
      input [2:0] rd;
      input [7:0] imm8;

      begin
	 $display(" Decoded instruction: movi with rd=%d, imm8=%d", rd, imm8);
	 // do the move operation.
	 r[rd] = imm8;
	 // Should always be positive, as we only have an 8 bit immediate.
	 N = 0;
	 setZ(r[rd]);
	 // C and V unchanged
      end
   endtask // movi

   task movnr;
      input [2:0] rd;
      input [2:0] rm;

      begin
	 $display(" Decoded instruction: movnr with rd=%d, rm=%d", rd, rm);
	 r[rd] = ~r[rm];
	 N = r[rd][31];
	 setZ(r[rd]);
	 // Never shifted
	 C = 0;
	 // V unchanged
      end
   endtask // movnr

   task movrsp;
      input [2:0] rm;

      begin
	 $display(" Decoded instruction: movrsp with rm=%d", rm);
	 r[13] = r[rm];
      end
   endtask // movrsp
     
   task ldri;
      input [2:0] rt;
      input [2:0] rn;
      input [4:0] imm5;
      reg [31:0]  offset_addr;

      begin
	 $display(" Decoded instruction: ldri with rt=%d, rn=%d, imm5=%d", rt, rn, imm5);
	 offset_addr = {{25{1'b0}}, imm5, 2'b00};
	 offset_addr = offset_addr + r[rn];
	 offset_addr = offset_addr >> 2;
	 
	 r[rt] = memory[offset_addr];
      end
   endtask // ldri

   task ldrr;
      input [2:0] rt;
      input [2:0] rn;
      input [2:0] rm;
      reg [31:0]  offset_addr;

      begin
	 $display(" Decoded instruction: ldrr with rt=%d, rn=%d, rm=%d", rt, rn, rm);
	 offset_addr = r[rm] + r[rn];
	 offset_addr = offset_addr >> 2;
	 r[rt] = memory[offset_addr];
      end
   endtask // ldrr

   task ldrspi;
      input [2:0] rt;
      input [7:0] imm8;
      reg [31:0]  offset_addr;

      begin
	 $display(" Decoded instruction: ldrspi with rt=%d, imm8=%d", rt, imm8);
	 offset_addr = {{22{1'b0}}, imm8, 2'b00};
	 offset_addr = offset_addr + r[13];
	 offset_addr = offset_addr >> 2;
	 
	 r[rt] = memory[offset_addr];
      end
   endtask // ldrspi

   task ldrpci;
      input [2:0] rd;
      input [7:0] imm8;
      reg [31:0]  addr;

      begin
	 $display(" Decoded instruction: ldrpci with rd=%d, imm8=%d", rd, imm8);
	 addr = {{22{1'b0}}, imm8, 2'b00};
	 addr = addr + r[15];
	 r[rd] = memory[addr];
      end
   endtask // ldrpci

   task stri;
      input [2:0] rt;
      input [2:0] rn;
      input [4:0] imm5;
      reg [31:0]  offset_addr;
      
      begin
	 $display(" Decoded instruction: stri with rt=%d, rn=%d, imm5=%d", rt, rn, imm5);
	 offset_addr = {{25{1'b0}}, imm5, 2'b00};
	 offset_addr = offset_addr + r[rn];
	 offset_addr = offset_addr >> 2;
	 
	 memory[offset_addr] = r[rt];
      end
   endtask // stri

   task strr;
      input [2:0] rt;
      input [2:0] rn;
      input [2:0] rm;
      reg [31:0]  offset_addr;
      
      begin
	 $display(" Decoded instruction: strr with rt=%d, rn=%d, rm=%d", rt, rn, rm);
	 offset_addr = r[rn] + r[rm];
	 offset_addr = offset_addr >> 2;
	 memory[offset_addr] = r[rt];
      end
   endtask // strr

   task strspi;
      input [2:0] rt;
      input [7:0] imm8;
      integer 	  offset_addr;
      
      begin
	 $display(" Decoded instruction: strspi with rt=%d, imm8=%d", rt, imm8);
	 offset_addr = {{22{1'b0}}, imm8, 2'b00};
	 offset_addr = offset_addr + r[13];
	 offset_addr = offset_addr >> 2;
	 memory[offset_addr] = r[rt];
      end
   endtask // strspi
   
   task push;
      reg [31:0] addr;
      
      begin
	 $display(" Decoded instruction: push");
	 // SP counts in bytes, so divide by 4. Something about wizards.
	 addr = r[13] >> 2;
	 addr = addr - 1;
	 memory[addr] = r[14];
	 r[13] = addr << 2;
      end
   endtask // push

   task pop;
      reg [31:0] addr;
      
      begin
	 $display(" Decoded instruction: pop");
	 addr = r[13] >> 2;
	 BranchWritePC(memory[addr]);
	 addr = addr + 1;
	 r[13] = addr << 2;
	 
	 if (r[13] > 32'h1000) begin
	    $display("Error: Tried to pop an empty stack.");
	    $finish;
	 end
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
      reg [31:0]   imm32;
      
      begin
	 $display(" Decoded instruction: bu with imm11=%d", imm11);
	 imm32 = {{20{imm11[10]}}, imm11, 1'b0};
	 BranchWritePC(r[15] + imm32);
      end
   endtask // bu

   task conditionPassed;
      input [3:0] cond;
      output 	  result;
      reg 	  pass;
      
      begin
	 casez (cond)
	   // EQ (NE)
	   4'b000z: pass = (Z == 1);
	   // GE (LT)
	   4'b101z: pass = (N == V);
	   // GT (LE)
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
      end
   endtask // conditionPassed
   
   task b;
      input [3:0] cond;
      input [7:0] imm8;
      reg 	  condT;
      reg [31:0]  imm32;
      
      begin
	 // Print cond as binary - more useful.
	 $display(" Decoded instruction: b with cond=%b, imm8=%d", cond, imm8);
	 conditionPassed(cond, condT);

	 if (condT == 1) begin
	    imm32 = {{23{imm8[7]}}, imm8, 1'b0};
	    BranchWritePC(r[15] + imm32);
	 end
      end
   endtask // b

   task bl;
      input [10:0] imm11;

      begin
	 $display(" Decoded instruction: bl1 with imm11=%d", imm11);
	 // When executing, BL2 should be in fetched.
	 if (fetched[15:11] != 5'b11111) begin
	    // Shouldn't happen unless memory has been tampered with.
	    $display("Error: Found BL1, but it was not followed by BL2.");
	    $display("       Actually fetched: %b", fetched);
	    $finish;
	 end else begin
	    // Decode BL2 and combine.
	    bl_32(imm11[10], imm11[9:0], fetched[10:0]);
	 end
      end
   endtask

   task bl_32;
      input        S;
      input [9:0]  bl1_imm10;
      input [10:0] bl2_imm11;
      reg [31:0]   imm32;
      
      begin
	 $display(" Decoded instruction: bl(2) with bl1_imm11=%d, bl2_imm11=%d", {S, bl1_imm10}, bl2_imm11);
	 imm32 = {{{10{S}}}, bl1_imm10, bl2_imm11, 1'b0};

	 // Set LR
	 r[14] = {r[15][31:1], 1'b1};
	 BranchWritePC(r[15] + imm32);
      end
   endtask // bl_32
   
   task br;
      input [2:0] rm;
      reg [31:0]  addr;
      
      begin
	 $display(" Decoded instruction: br with rm=%d", rm);
	 //branch to reg
	 addr = r[rm];
	 addr[0] = 1'b0;
	 BranchTo(r[rm]);
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
	 for (addr = 0; addr < 4096; addr = addr + 4) begin
	    $display("%h:  %h", addr, memory[addr / 4]);
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
	   16'b00000zzzzzzzzzzz: lsli(in[2:0], in[5:3], in[10:6]);
	   //  15   10 7 5  2 0
	   16'b00001zzzzzzzzzzz: lsri(in[2:0], in[5:3], in[10:6]);
	   16'b00010zzzzzzzzzzz: asri(in[2:0], in[5:3], in[10:6]);
	   16'b00100zzzzzzzzzzz: movi(in[10:8], in[7:0]);
	   16'b00110zzzzzzzzzzz: addi(in[10:8], in[7:0]);
	   16'b00111zzzzzzzzzzz: subi(in[10:8], in[7:0]);
	   //  15   10 7 5  2 0
	   16'b01001zzzzzzzzzzz: ldrpci(in[10:8], in[7:0]);
	   16'b01100zzzzzzzzzzz: stri(in[2:0], in[5:3], in[10:6]);
	   16'b01101zzzzzzzzzzz: ldri(in[2:0], in[5:3], in[10:6]);
	   16'b10010zzzzzzzzzzz: strspi(in[10:8], in[7:0]);
	   16'b10011zzzzzzzzzzz: ldrspi(in[10:8], in[7:0]);
	   //  15   10 7 5  2 0
	   16'b10100zzzzzzzzzzz: addpci(in[10:8], in[7:0]);
	   16'b10101zzzzzzzzzzz: addspi(in[10:8], in[7:0]);
	   16'b11100zzzzzzzzzzz: bu(in[10:0]);
	   16'b11110zzzzzzzzzzz: bl(in[10:0]);
	   16'b1101zzzzzzzzzzzz: b(in[11:8], in[7:0]);
	   //  15   10 7 5  2 0
	   16'b11111zzzzzzzzzzz: begin
	      $display("Error: Found BL2 without preceeding BL1");
	      $finish;
	   end
	   default: begin
	      $display("Error: Unrecognised instruction: %h", in);
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
      $readmemh("bubble.emu", memory);
      
      clock = 0;
      r[15] = 0;
      Z = 0;
      N = 0;
      C = 0;
      V = 0;

      // Set the anti loop counter. Simulator specific.
      blankFetch = 0;
   end

   // simulate the clock
   always #1 clock = !clock;

   // perform a fetch-decode-execute cycle
   always @ ( posedge clock ) begin
      if (fetched === 16'bxxxxxxxxxxxxxxxx) begin
	 if (blankFetch > 2) begin
	    // Protect against infinite loops if branch destination/input is bad.
	    $display("Error: Stopping emulator, it appears execution has left the program.");
	    $finish;
	 end else begin
	    $display("Pipeline empty, fetching.");
	    fetch();

	    blankFetch = blankFetch + 1;
	 end
      end else begin	 
	 $display(" Executing instruction @ %h: '%b'", r[15] - 2, fetched);
	 fetch();
	 decode(executing);
	 printTrace();

	 blankFetch = 0;
      end
      
   end

endmodule