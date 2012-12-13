/*
This test stimulus is a little more complicated than some of those you've 
used thus far.  On one hand the structure is roughly the same, and you in
no way *need* to understand all aspects of this implementation *if* you 
can implement the Device Under Test (DUT) correctly.  On the other hand, 
some features warrant explanation:
 
- An instance of the DUT, i.e., the module we are testing, is created and 
  called t; we connect an input (resp. output) to (resp. from) t called X 
  to a register (resp. wire) called called t_X.
- The user defined task called test applies the i-th test vector in a way
  that matches the implementation strategy of the DUT.  Basically it reads 
  each input to t called X from a memory called v_X, performs an encryption,
  then compares the resulting output with v_Y.
*/

module encrypt_v1_test();

  parameter b = 64;                     // b-bit message size
  parameter k = 80;                     // k-bit key     size
  parameter r = 31;                     // r     encryption rounds
  parameter l =  8;                     // l     test vectors
   
  reg  [ k - 1 : 0 ] t_K;               // DUT key                input
  reg  [ b - 1 : 0 ] t_M;               // DUT plaintext  message input
  wire [ b - 1 : 0 ] t_C;               // DUT ciphertext message output
  reg  [ b - 1 : 0 ] t_T;

  reg  [ k - 1 : 0 ] v_K [ 0 : l - 1 ]; // test vector keys              
  reg  [ b - 1 : 0 ] v_M [ 0 : l - 1 ]; // test vector plaintext  messages
  reg  [ b - 1 : 0 ] v_C [ 0 : l - 1 ]; // test vector ciphertext messages

  integer i;

  encrypt_v1 t( .K( t_K ), .M( t_M ), .C( t_C ) );

  task test( input integer i ); 
    begin
          t_K = v_K[ i ];
          t_M = v_M[ i ];

          $display( "-> Enc(%h,%h)", t_K, t_M );

      #10 t_T = t_C;

          $display( "<- %h [%s]", t_T, ( t_T === v_C[ i ] ) ? "pass" : "fail" );
    end
  endtask

  initial begin
        $readmemh( "./vectors_k.txt", v_K );
        $readmemh( "./vectors_m.txt", v_M );
        $readmemh( "./vectors_c.txt", v_C );     
     
        $dumpfile( "encrypt_v1_test.vcd" );
        $dumplimit( 10485760 );
        $dumpvars;

    #10 $dumpon;

        for( i = 0; i < l; i = i + 1 ) begin
          test( i );
        end
     
    #10 $dumpoff;
    #10 $finish;
  end

endmodule
