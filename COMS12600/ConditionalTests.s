; COMS12600 emulator conditionals test file
; Simon Hollis 2011-13 (C) (simon@cs.bris.ac.uk)
; Solution pattern should be 16, 8, 42, 0

        THUMB

Start
        MOVI r0, #16
	SVC 0
	MOVI r1, #8
	SVC 1
	SUBR r0, r0, r1
	BLT Wrong  ; this branch shouldn't be taken
	BGT Right  ; this branch should be taken
	BU Wrong ; this branch shouldn't be taken

Wrong
        MOVI r0, #0x00af
	SVC 0  ; print out value
	BU Finish
Right
        MOVI r0, #42
	SVC 0 ; print out value

        ; next test
	SUBI r0, #42
	SVC 0
	BNE Wrong ; should not be taken
	BGT Wrong ; should not be taken
	BLT Wrong ; should not be taken
	BEQ Finish ; should be taken --- equal to zero
	BU Wrong ; should not be taken
Finish
	SVC 16 ; print all registers
	SVC 100 ; stop emulator
	
	END
