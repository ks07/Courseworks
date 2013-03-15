; ***************************************
; *** COMS12600 Bubblesort Assignment ***
; *** (C) Simon Hollis, 2011-13       ***
; *** simon@cs.bris.ac.uk             ***
; ***************************************
	
	THUMB
	
Start
	MOVI r0, #1
	LSLI r0, r0, #12	; load largest memory address 
	MOVRSP sp, r0 		; set stack pointer to largest value

	BU StartSort  		; start the work


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
	SVC 101		      	; print out starting memory values
	MOVI r1, #DataStart 	; load start address for the data values
MainLoop
	BL OnePass		; perform a single pass of bubble sort
	SUBI r3, #1		; if (r3 == 1)
	BEQ MainLoop		;   goto MainLoop
	BU Stop

	; **** Sub-routines Below ****

OnePass				; subroutine for performing a single loop through the data
	PUSH {lr}
	;; Assumes that r1 is the first element, and that (r2, r3, r4, r5, r7) are safe to modify.
	MOVI r2, #0 		; r2 holds the array index. r2 = 0.
	MOVI r3, #0		; r3 holds the boolean swapped flag.
	MOVI r6, #DataEnd	; r6 = r1 + length(array)
OPLoop
	LDRR r4, [r1, r2] 	; r4 = array[r2]. r4 holds the current item to compare
	ADDI r2, #4 		; r2++
	LDRR r5, [r1, r2] 	; r5 = array[r2]. r5 holds the item to compare with

	SUBR r7, r5, r4		; if (r5 > r4)
	BLT NoSwap		;   goto NoSwap
	MOVI r3, #1		; swapped = true
	EORR r4, r5		; use the XOR trick to swap variables.
	EORR r5, r4		; r4 <=> r5 s.t. r5 > r4
	EORR r4, r5		; r5 is now the greater of the two.
NoSwap
	STRR r5, [r1, r2]	; array[r2] = r5
	SUBI r2, #4		; r2--
	STRR r4, [r1, r2]	; array[r2] = r4

	ADDI r2, #4		; r2++. Increment loop counter.
	SUBR r7, r2, r6		; if (r2 < r6)
	BLT OPLoop		;   goto OPLoop
	POP {pc}		; return from the subroutine
	;; End of Sub: OnePass

DumpRegs
        PUSH {lr} 		; save return address onto stack
	SVC 101			; print memory after finishing sort
	SVC 16 			; debug command to dump all registers
	POP {pc} 		; return to calling sub-routine
	
Stop
	BL DumpRegs 		; print all the registers
	SVC 100 		; stop the emulator
	
	END
