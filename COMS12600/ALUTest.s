; COMS12600 emulator ALU test file
; Simon Hollis 2011-2013 (C) (simon@cs.bris.ac.uk)
; Solution pattern should be 42, 43, 84, 168, 0 from r0

        THUMB	
Start
	MOVI r0, #42
	MOVI r1, #42
	SVC 0 ; print that r0 is 42
	ADDI r0, #1
	SVC 0 ; print that r0 is 43
	SUBI r0, #1
	ADDR r0, r1
	SVC 0 ; print that r0 should be 84 
	MOVI r2, #2
	MULR r0, r2 ; result is 168
	SVC 0 ; print r0
	MOVI r1, #168
	EORR r0, r1 ; r0 should equal zero
	SVC 0 ; print r0
	SVC 16  ; print out all the registers

Stop
	SVC 100 ; stop the emulator

	END
