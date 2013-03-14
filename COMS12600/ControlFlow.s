; Control flow test program
; COMS12600
; Simon Hollis (simon@cs.bris.ac.uk)
; March 2013

     THUMB

Start
       MOVI r0, #1
       SVC 0 ; print out r0
       BU Second ; jump down

Third
      MOVI r0, #3
      SVC 0  ; print out r0
      BU Fourth  ; jump down

Fourth
      MOVI r0, #4
      SVC 0 ; print out r0
      BU Finish ; jump to end

Second
      MOVI r0, #2
      SVC 0 ; print out r0
      BU Third  ; jump up

Finish
      SVC 16  ; print all registers
      SVC 100 ; stop emulator
