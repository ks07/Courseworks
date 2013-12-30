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
ADD          : '+'  ;
SUB          : '-'  ;
MUL          : '*'  ;
DIV          : '/'  ;
OPENSQ       : '['  ;
CLOSESQ      : ']'  ;
COMMA        : ','  ;

REALNUM      : INT '.' INT (EXPONENT)? ;

fragment 
EXPONENT     : 'e' ('-')? INT ;

fragment 
INT          : ('0'..'9')+ ;

STRING       : '\'' ('\'' '\'' | ~'\'')* '\'' ;

COMMENT      : '{' (~'}')* '}' {skip();} ;

WS           : (' ' | '\t' | '\r' | '\n' )+ {skip();} ;

LT : '<' ;
LTE : '<=' ;
GT : '>' ;
GTE : '>=' ;
EQ : '=' ;
NEQ : '!=' ;

//RELATION     : ('<' | '<=' | '!=' | '=' | '>=' | '>') ;

//UNARYOP      : ( '+' | '-' )? ;

IDENTIFIER
    : ( 'a'..'z' | 'A'..'Z' )( ( 'a'..'z' | 'A'..'Z' | '0'..'9' ) )* ;
