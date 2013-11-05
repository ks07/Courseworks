// COMS22303: Lexical analyser

lexer grammar Lex;

//---------------------------------------------------------------------------
// KEYWORDS
//---------------------------------------------------------------------------
BEGIN      : 'begin' ;
END        : 'end' ;
WRITE      : 'write' ;
WRITELN    : 'writeln' ;
ARRAY      : 'array' ;
ELSE       : 'else' ;
IF         : 'if' ;
READ       : 'read' ;
REPEAT     : 'repeat' ;
UNTIL      : 'until' ;

//---------------------------------------------------------------------------
// OPERATORS
//---------------------------------------------------------------------------
SEMICOLON    : ';'  ;
OPENPAREN    : '('  ;
CLOSEPAREN   : ')'  ;
ASSIGN       : ':=' ;

CONSTANT     : REALNUM ;

REALNUM      : INT '.' INT (EXPONENT)?;

fragment 
EXPONENT     : 'e' ('-')? INT ;

fragment 
INT          : ('0'..'9')+ ;

STRING       : '\'' ('\'' '\'' | ~'\'')* '\'';

COMMENT      : '{' (~'}')* '}' {skip();} ;

WS           : (' ' | '\t' | '\r' | '\n' )+ {skip();} ;

RELATION     : ('<' | '<=' | '!=' | '=' | '>=' | '>') ;

EXPRESSION   : UNARYOP TERM ( ( '+' | '-' ) TERM )* ;

fragment
UNARYOP      : ( '+' | '-' )? ;

fragment
TERM         : FACTOR ( ( '*' | '/' ) FACTOR )* ;

fragment
FACTOR       : ( VARIABLE | CONSTANT | OPENPAREN EXPRESSION CLOSEPAREN ) ;

fragment
VARIABLE     : IDENTIFIER ( '[' EXPRESSION ']' )? ;

CMPSTATEMENT : BEGIN ( STATEMENT SEMICOLON )* END ;

STATEMENT    : ( ASSIGNMENT
               | READ OPENPAREN VARIABLE CLOSEPAREN
               | WRITE OPENPAREN OPENPAREN ( EXPRESSION | STRING ) CLOSEPAREN
               | WRITELN
               | BRANCH
               | LOOP ) ;

fragment
ASSIGNMENT   : VARIABLE ASSIGN EXPRESSION ;

fragment
BRANCH       : IF BOOLCMP
               CMPSTATEMENT
               ( ELSE CMPSTATEMENT )? ;

fragment
LOOP         : REPEAT CMPSTATEMENT
               UNTIL BOOLCMP ;

fragment
BOOLCMP      : EXPRESSION RELATION EXPRESSION ;

IDENTIFIER
@init { int N = 1; }
    : ( 'a'..'z' | 'A'..'Z' )( { N < 9 }?=> ( 'a'..'z' | 'A'..'Z' | '0'..'9' ) { N++; } )* ;
