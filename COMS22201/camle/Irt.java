// COMS22303: IR tree construction
//
// This program converts an Abstract Syntax Tree produced by ANTLR to an IR tree.
// The Abstract Syntax Tree has type CommonTree and can be walked using 5 simple
// methods.  If ast is a CommonTree and t is a Token:
//   
//   int        ast.getChildCount();                       // Get # of subtrees
//   CommonTree (CommonTree)ast.getChild(int childNumber); // Get a subtree
//   Token      ast.getToken();                            // Get a node's token
//   int        t.getType();                               // Get token type
//   String     t.getText();                               // Get token text
//
// Every method below has two parameters: the AST (input) and IR tree (output).
// Some methods (arg()) return the type of the item processed.

import java.util.*;
import java.io.*;
import java.lang.reflect.Array;
import antlr.collections.AST;
import org.antlr.runtime.*;
import org.antlr.runtime.tree.*;

public class Irt
{
// The code below is generated automatically from the ".tokens" file of the 
// ANTLR syntax analysis, using the TokenConv program.
//
// CAMLE TOKENS BEGIN
  public static final String[] tokenNames = new String[] {
"NONE", "NONE", "NONE", "NONE", "BEGIN", "END", "WRITE", "WRITELN", "ARRAY", "ELSE", "IF", "READ", "REPEAT", "UNTIL", "SEMICOLON", "OPENPAREN", "CLOSEPAREN", "ASSIGN", "ADD", "SUB", "MUL", "DIV", "OPENSQ", "CLOSESQ", "COMMA", "INT", "EXPONENT", "REALNUM", "STRING", "COMMENT", "WS", "LT", "LTE", "GT", "GTE", "EQ", "NEQ", "IDENTIFIER"};
  public static final int CLOSEPAREN=16;
  public static final int EXPONENT=26;
  public static final int LT=31;
  public static final int GTE=34;
  public static final int OPENSQ=22;
  public static final int ELSE=9;
  public static final int SUB=19;
  public static final int INT=25;
  public static final int SEMICOLON=14;
  public static final int LTE=32;
  public static final int MUL=20;
  public static final int WRITE=6;
  public static final int IF=10;
  public static final int NEQ=36;
  public static final int WS=30;
  public static final int WRITELN=7;
  public static final int READ=11;
  public static final int COMMA=24;
  public static final int UNTIL=13;
  public static final int IDENTIFIER=37;
  public static final int BEGIN=4;
  public static final int REALNUM=27;
  public static final int ASSIGN=17;
  public static final int CLOSESQ=23;
  public static final int GT=33;
  public static final int REPEAT=12;
  public static final int OPENPAREN=15;
  public static final int DIV=21;
  public static final int EQ=35;
  public static final int END=5;
  public static final int COMMENT=29;
  public static final int ARRAY=8;
  public static final int STRING=28;
  public static final int ADD=18;
// CAMLE TOKENS END

    public static IRTree convert(CommonTree ast)
    {
	IRTree irt = new IRTree();
	program(ast, irt);
	return irt;
    }

    // Convert a program AST to IR tree
    public static void program(CommonTree ast, IRTree irt)
    {
	if (ast.getToken().getType() == ARRAY) {
	    // Program starts with some array declarations.
	    //	    declarations(
	}
	statements(ast, irt);
    }

    // Converts a program AST, starting with array declarations, to IR tree
    public static void declarations(CommonTree ast, IRTree irt) {
	CommonTree ast1 = (CommonTree)ast.getChild(0);
	//	int tt = t.getType();
	//	while (tt != BEGIN) {


	//}
	statements(ast, irt);
    }

    // Convert a compoundstatement AST to IR tree
    public static void statements(CommonTree ast, IRTree irt)
    {
	Token t = ast.getToken();
	int tt = t.getType();
	if (tt == BEGIN) {
	    int n = ast.getChildCount();
	    if (n == 0) {
		irt.setOp("NOOP");
	    }
	    else {
		CommonTree ast1 = (CommonTree)ast.getChild(0);
		statements1(ast, 0, n-1, irt);
	    }
	} else {
	    error(tt);
	}
    }

    public static void statements1(CommonTree ast, int first, int last, IRTree irt)
    {
	CommonTree ast1 = (CommonTree)ast.getChild(first);
	if (first == last) {
	    statement(ast1, irt);
	}
	else {
	    IRTree irt1 = new IRTree();
	    IRTree irt2 = new IRTree();
	    statement(ast1, irt1);
	    statements1(ast, first+1, last, irt2);
	    irt.setOp("SEQ");
	    irt.addSub(irt1);
	    irt.addSub(irt2);
	}
    }

    // Convert a statement AST to IR tree
    public static void statement(CommonTree ast, IRTree irt)
    {
	CommonTree ast1, ast2, ast3;
	IRTree irt1 = new IRTree();
	IRTree irt2, irt3;
	Token t = ast.getToken();
	int tt = t.getType();
	switch (tt) {
	case WRITELN:
	    String a = String.valueOf(Memory.allocateString("\n"));
	    irt.setOp("WRS");
	    irt.addSub(new IRTree("MEM", new IRTree("CONST", new IRTree(a))));
	    break;
	case WRITE:
	    ast1 = (CommonTree)ast.getChild(0);
	    String type = arg(ast1, irt1);
	    if (type.equals("real")) {
		irt.setOp("WRR");
		irt.addSub(irt1);
	    }
	    else {
		irt.setOp("WRS");
		irt.addSub(irt1);
	    }
	    break;
	case ASSIGN:
	    // Child 0 should be an identifier, 1 should be expression.
	    // <variable> ':=' <expression>
	    ast1 = (CommonTree)ast.getChild(0);
	    ast2 = (CommonTree)ast.getChild(1);
	    irt.setOp("STORE");
	    irt2 = new IRTree();

	    // Prepare irt1/2.
	    variable(ast1, irt1);
	    expression(ast2, irt2);

	    irt.addSub(irt1);
	    irt.addSub(irt2);
	    break;
	case READ:
	    ast1 = (CommonTree)ast.getChild(0);
	    irt.setOp("READ");
	    variable(ast1, irt1);
	    irt.addSub(irt1);
	    break;
	case IF:
	    ast1 = (CommonTree)ast.getChild(0);
	    ast2 = (CommonTree)ast.getChild(1); // TRUE AST
	    irt2 = new IRTree();
	    irt.setOp("CJUMP");
	    condition(ast1, irt1);
	    statements(ast2, irt2); // Use compoundstatement on TRUE branch

	    irt.addSub(irt1);
	    irt.addSub(irt2);

	    // Determine if this is an if...else statement
	    ast3 = (CommonTree)ast.getChild(2);
	    if (ast3 != null) {
		irt3 = new IRTree();
		statements(ast3, irt3); // ELSE branch
		irt.addSub(irt3);
	    }
	    break;
	case REPEAT:
	    ast1 = (CommonTree)ast.getChild(0); // compoundstatement
	    ast2 = (CommonTree)ast.getChild(1); // until condition
	    irt2 = new IRTree();
	    irt.setOp("LOOP");
	    statements(ast1, irt1);
	    condition(ast2, irt2);

	    irt.addSub(irt1);
	    irt.addSub(irt2);
	    break;
	default:
	    error(tt);
	    break;
	}
    }

    // Convert a condition AST to IR tree
    public static void condition(CommonTree ast, IRTree irt) {
	Token t = ast.getToken();
	CommonTree ast1 = (CommonTree)ast.getChild(0);
	CommonTree ast2 = (CommonTree)ast.getChild(1);
	IRTree irt1 = new IRTree();
	IRTree irt2 = new IRTree();
        expression(ast1, irt1);
	expression(ast2, irt2);
	switch (t.getType()) {
	case LT:
	    irt.setOp("LT");
	    break;
	case LTE:
	    irt.setOp("LE");
	    break;
	case GT:
	    irt.setOp("GT");
	    break;
	case GTE:
	    irt.setOp("GE");
	    break;
	case EQ:
	    irt.setOp("EQ");
	    break;
	case NEQ:
	    irt.setOp("NE");
	    break;
	default:
	    error(t.getType());
	    break;
	}
	irt.addSub(irt1);
	irt.addSub(irt2);
    }

    // Convert an identifier AST to IR tree
    public static void variable(CommonTree ast, IRTree irt)
    {
	Token t = ast.getToken();
	int tt = t.getType();
	if (tt == IDENTIFIER) {
	    String varname = t.getText();
	    int addr = Memory.alloc(varname);
	    irt.setOp("MEM");
	    irt.addSub(new IRTree(varname)); // Don't store addr here, instead use name
	} else {
	    error(tt);
	}
    }

    // Convert an arg AST to IR tree
    public static String arg(CommonTree ast, IRTree irt)
    {
	Token t = ast.getToken();
	int tt = t.getType();
	if (tt == STRING) {
	    String tx = t.getText();
	    int a = Memory.allocateString(tx); 
	    String st = String.valueOf(a);
	    irt.setOp("MEM");
	    irt.addSub(new IRTree("CONST", new IRTree(st)));
	    return "string";
	}
	else {
	    expression(ast, irt);
	    return "real";
	}
    }

    // Convert an expression AST to IR tree
    public static void expression(CommonTree ast, IRTree irt)
    {
	CommonTree ast1, ast2;
	IRTree irt1 = new IRTree();
	IRTree irt2 = new IRTree();
	Token t = ast.getToken();
	int tt = t.getType();
	switch (tt) {
	case REALNUM:
	    constant(ast, irt1);
	    irt.setOp("CONST");
	    irt.addSub(irt1);
	    break;
	case IDENTIFIER:
	    // Variable
	    ast1 = (CommonTree)ast.getChild(0);
	    irt.setOp("MEM");
	    irt.addSub(new IRTree(t.getText()));
	    break;
	case ADD:
	    irt.setOp("ADDR");
	    // Unary operator, i.e. sign, so only 1 child
	    if (ast.getChild(1) == null) {
		ast1 = (CommonTree)ast.getChild(0);
		expression(ast1, irt1); // Recurse
		irt.addSub(irt1);
	    } else {
		// Left sub-tree
		ast1 = (CommonTree)ast.getChild(0);
		expression(ast1, irt1);
		irt.addSub(irt1);
		// Right sub-tree
		ast2 = (CommonTree)ast.getChild(1);
		expression(ast2, irt2);
		irt.addSub(irt2);
	    }
	    break;
	case SUB:
	    irt.setOp("SUBR");
	    // Unary operator, i.e. sign, so only 1 child
	    if (ast.getChild(1) == null) {
		ast1 = (CommonTree)ast.getChild(0);
		expression(ast1, irt1); // Recurse
		irt.addSub(irt1);
	    } else {
		// Left sub-tree
		ast1 = (CommonTree)ast.getChild(0);
		expression(ast1, irt1);
		irt.addSub(irt1);
		// Right sub-tree
		ast2 = (CommonTree)ast.getChild(1);
		expression(ast2, irt2);
		irt.addSub(irt2);
	    }
	    break;
	case MUL:
	    irt.setOp("MULR");
	    // No unary operations here.
	    ast1 = (CommonTree)ast.getChild(0);
	    expression(ast1, irt1);
	    irt.addSub(irt1);
	    ast2 = (CommonTree)ast.getChild(1);
	    expression(ast2, irt2);
	    irt.addSub(irt2);
	    break;
	case DIV:
	    irt.setOp("DIVR");
	    // No unary operations here.
	    ast1 = (CommonTree)ast.getChild(0);
	    expression(ast1, irt1);
	    irt.addSub(irt1);
	    ast2 = (CommonTree)ast.getChild(1);
	    expression(ast2, irt2);
	    irt.addSub(irt2);
	    break;
	default:
	    error(tt);
	    break;
	}
    }

    // Convert a constant AST to IR tree
    public static void constant(CommonTree ast, IRTree irt)
    {
	Token t = ast.getToken();
	int tt = t.getType();
	if (tt == REALNUM) {
	    String tx = t.getText();
	    irt.setOp(tx);
	}
	else {
	    error(tt);
	}
    }

    private static void error(int tt)
    {
	System.out.println("IRT error: "+tokenNames[tt]);
	System.exit(1);
    }
}
