; ***************************************
; *** COMS12600 Bubblesort Assignment ***
; *** (C) Simon Hollis, 2011-13       ***
; *** simon@cs.bris.ac.uk             ***
; ***************************************
	
	THUMB
	
Start
       MOVI r0, #1 
       LSLI r0, r0, #12 ; load largest memory address
       MOVRSP sp, r0 ; set stack pointer to largest value
       
       BU StartSort  ; start the work


; *** The data values to be sorted
; *** DCD is an assembler directive to insert the given constant in memory
DataStart
	DCD -4
	DCD 2
	DCD 5
	DCD 910
	DCD 10
	DCD -12
	DCD 91
	DCD 11
DataEnd

StartSort
	MOVI r1, #DataStart  ; load start address for the data values
	MOVI r2, #0 ; array index being sorted
	LDRR r4, [r1, r2] ; get first data item
	ADDI r2, #4 ;
	LDRR r5, [r1, r2] ; get second data item

	
	; *** INSERT YOUR SORTING CODE HERE ***
	SUBR r7, r5, r4		; subtract 2nd from 1st to compare
	BGT Swap
	BU NoSwap
Swap
	EORR r4, r5		; use the XOR trick to swap variables.
	EORR r5, r4		;
	EORR r5, r4		; r5 and r4 are now swapped
NoSwap
	BU EndSort

EndSort
	BU Stop

	
	; **** One way to use the SVCs 
	; **** (as sub-routine calls to the SVCs)
	
DumpRegs 
        PUSH {lr} ; save return address onto stack
	SVC 16 ; debug command to dump all registers
	POP {pc} ; return to calling sub-routine
	
PrintR0
        PUSH {lr} ; save return address onto stack
	SVC 0 ; debug command to printR0
	POP {pc} ; return to calling sub-routine
	
Stop
	BL DumpRegs ; print all the registers
	SVC 100 ; stop the emulator
	
	
	END
