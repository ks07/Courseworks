// COMS22303: Syntax analyser

parser grammar Syn;

options {
  tokenVocab = Lex;
  output = AST;
}

@members
{
    // Implement our own error reporting.
    // http://www.antlr.org/wiki/display/ANTLR3/Error+reporting+and+recovery
    public void displayRecognitionError(String[] tokens, RecognitionException e) {
        String hdr = getErrorHeader(e);
        String msg = getErrorMessage(e, tokens);
        if (e instanceof MismatchedTokenException) {
            displayMismatchError(tokens, (MismatchedTokenException) e);
        } else {
            // Some other type of error, fallback to standard error message.
            System.err.println("ERROR: " + hdr + " " + msg);
        }
        System.out.println("Stopping compilation, error detected.");
        System.exit(1); // Cancel compilation if we've met an error.
    }

    private void displayMismatchError(String[] tokens, MismatchedTokenException e) {
        String expected = tokens[e.expecting];
        String hdr = getErrorHeader(e);
        String msg = getErrorMessage(e, tokens);

        switch (expected) {
        case "BEGIN":
            System.err.println("ERROR: Program must begin with 'begin'. Expected at " + hdr);
            break;
        case "END":
            System.err.println("ERROR: Program must end with 'end'.");
            break;
        case "CLOSEPAREN":
            System.err.println("ERROR: Mismatched parentheses at " + hdr);
            break;
        case "ASSIGN":
            System.err.println("ERROR: Missing assignment operator at " + hdr);
            System.err.println("  Perhaps you have misspelt a keyword?");
            break;
        default:
            System.err.println("Unhandled expected: " + expected);
            System.err.println(hdr + " " + msg);
            break;
        }
    }

	private String cleanString(String s){
		String tmp;
		tmp = s.replaceAll("^'", "");
		s = tmp.replaceAll("'$", "");
		tmp = s.replaceAll("''", "'");
		return tmp;
	}
}

// Want to be able to parse array declarations recursively.
program :
	( ARRAY^ arrays )? compoundstatement
  ;

arrays :
	declaration ( COMMA! declaration )* SEMICOLON!
  ;

declaration :
    IDENTIFIER^ OPENSQ! constant CLOSESQ!
    ;

compoundstatement :
    BEGIN^ ( statement SEMICOLON! )* END!
  ;

// ! = dont show in tree
// ^ = make root
statement :
    WRITE^ OPENPAREN! ( expression | string ) CLOSEPAREN!
  | WRITELN
  | READ^ OPENPAREN! variable CLOSEPAREN!
  | IF^ boolcmp compoundstatement ( ELSE! compoundstatement )?
  | REPEAT^ compoundstatement UNTIL! boolcmp
  | variable ASSIGN^ expression
  ;

//aop :
//        ( ADD | SUB )
//    ;

relation :
        ( GT | LT | GTE | LTE | EQ | NEQ )
    ;

expression:
        ((( ADD | SUB )^ )? term ) (( ADD | SUB )^ term )*
  ;

//unaryop :
//        ( aop^ )?
//    ;

term: 
    factor ( ( MUL | DIV )^ factor )*
    ;

factor :
    OPENPAREN! expression^ CLOSEPAREN!
    | constant
    | variable
    ;

constant:
    REALNUM 
  ;

variable :
    IDENTIFIER^ ( OPENSQ! expression CLOSESQ! )?
    ;

string
    scope { String tmp;}
    :
    s=STRING { $string::tmp = cleanString($s.text); }-> STRING[$string::tmp]
  ;

boolcmp :
    expression relation^ expression;

