// COMS22303: Syntax analyser

parser grammar Syn;

options {
  tokenVocab = Lex;
  output = AST;
}

@members
{
	private String cleanString(String s){
		String tmp;
		tmp = s.replaceAll("^'", "");
		s = tmp.replaceAll("'$", "");
		tmp = s.replaceAll("''", "'");
		return tmp;
	}
}

program :
        ( ARRAY declaration ( COMMA declaration )* SEMICOLON! )? compoundstatement
  ;

declaration :
    IDENTIFIER OPENSQ! constant CLOSESQ!
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
  | IF^ boolcmp compoundstatement ( ELSE compoundstatement )?
  | REPEAT^ compoundstatement UNTIL boolcmp
  | variable ASSIGN^ expression
  ;

relation :
        ( GT | LT | GTE | LTE | EQ | NEQ )^
    ;


expression:
    unaryop term ( AOP^ term )*
  ;

unaryop :
        ( AOP^ )?
    ;

term: 
    factor ( FOP^ factor )*
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
    expression relation expression;

