// COMS22303: Code generation

import java.util.*;
import java.io.*;
import java.lang.reflect.Array;
import antlr.collections.AST;
import org.antlr.runtime.*;
import org.antlr.runtime.tree.*;

public class Cg
{
    // Generate code from a program (in IRTree form)
    public static void program(IRTree irt, PrintStream o)
    {
	emit(o, "XOR R0,R0,R0");   // Initialize R0 to 0
	statement(irt, o);
	emit(o, "HALT");           // Program must end with HALT
	Memory.dumpData(o);        // Dump DATA lines: initial memory contents
    }

    // Generate code from a statement (in IRTree form)
    private static void statement(IRTree irt, PrintStream o)
    {
	if (irt.getOp().equals("SEQ")) {
	    statement(irt.getSub(0), o);
	    statement(irt.getSub(1), o);
	}
	else if (irt.getOp().equals("WRS") && irt.getSub(0).getOp().equals("MEM") && 
		 irt.getSub(0).getSub(0).getOp().equals("CONST")) {
	    String a = irt.getSub(0).getSub(0).getSub(0).getOp();
	    emit(o, "WRS "+a);
	}
	else if (irt.getOp().equals("WRR")) {
	    String e = expression(irt.getSub(0), o);
	    emit(o, "WRR "+e);
	} else if (irt.getOp().equals("STORE")) {
	    String e = expression(irt.getSub(1), o);
	    String v = variable(irt.getSub(0), o);
	    emit(o, "STORE " + e + "," + v);
	} else {
	    error(irt.getOp());
	}
    }

    // Generate code from a variable identifier (in IRTree form)
    private static String variable(IRTree irt, PrintStream o) {
	String result = "";
	switch (irt.getOp()) {
	case "MEM":
	    // TODO: Array support
	    String addr = Memory.lookup(irt.getSub(0).getOp());
	    result = Reg.newReg();
	    emit(o, "MOVIR " + result + "," + addr);
	    result = result + ",0"; // Variable only, no array index.
	    break;
	default:
	    error(irt.getOp());
	    break;
	}
	return result; // Return register contaning base addr and offset if applicable.
    }

    // Generate code from an expression (in IRTree form)
    private static String expression(IRTree irt, PrintStream o)
    {
	String result = "";
	switch (irt.getOp()) {
	case "CONST":
	    String t = irt.getSub(0).getOp();
	    result = Reg.newReg();
	    emit(o, "MOVIR "+result+","+t);
	    break;
	case "MEM":
	    // TODO: Array support
	    String addr = Memory.lookup(irt.getSub(0).getOp()); // Need to make float from addr
	    result = Reg.newReg();
	    emit(o, "MOVIR " + result + "," + addr);
	    // Re-use the address register for the value. Gets in the way of better optimisation?
	    emit(o, "LOAD " + result + "," + result + ",0");
	    break;
	case "ADDR":
	    if (irt.subCount() < 2) {
		String reg = expression(irt.getSub(0), o);
		result = Reg.newReg();
		emit(o, "ADDR " + result + ",R0," + reg);
	    } else {
		String reg1 = expression(irt.getSub(0), o);
		String reg2 = expression(irt.getSub(1), o);
		result = Reg.newReg();
		emit(o, "ADDR " + result + "," + reg1 + "," + reg2);
	    }
	    break;
	case "SUBR":
	    //System.out.println(irt);
	    if (irt.subCount() < 2) {
		String reg = expression(irt.getSub(0), o);
		result = Reg.newReg();
		emit(o, "SUBR " + result + ",R0," + reg);
	    } else {
		String reg1 = expression(irt.getSub(0), o);
		String reg2 = expression(irt.getSub(1), o);
		result = Reg.newReg();
		emit(o, "SUBR " + result + "," + reg1 + "," + reg2);
	    }
	    break;
	case "MULR":
	    {
	    String reg1 = expression(irt.getSub(0), o);
	    String reg2 = expression(irt.getSub(1), o);
	    result = Reg.newReg();
	    emit(o, "MULR " + result + "," + reg1 + "," + reg2);
	    }
	    break;
	case "DIVR":
	    {
	    String reg1 = expression(irt.getSub(0), o);
	    String reg2 = expression(irt.getSub(1), o);
	    result = Reg.newReg();
	    emit(o, "DIVR " + result + "," + reg1 + "," + reg2);
	    }
	    break;
	default:
	    error(irt.getOp());
	    break;
	}
	return result;  // Return name of the register holding expression's value
    }

    // Generate an instruction
    private static void emit(PrintStream o, String s)
    {
	o.println(s);
    }

    // Error
    private static void error(String op)
    {
	System.out.println("CG error: "+op);
	System.exit(1);
    }
}
