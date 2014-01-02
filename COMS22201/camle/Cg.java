// COMS22303: Code generation

import java.util.*;
import java.io.*;
import java.lang.reflect.Array;
import antlr.collections.AST;
import org.antlr.runtime.*;
import org.antlr.runtime.tree.*;

public class Cg
{
    private static int label = 0;

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
	    emit(o, "STORE " + e + "," + v + ",0");
	} else if (irt.getOp().equals("READ")) {
	    String v = variable(irt.getSub(0), o);
	    String r = Reg.newReg(); // Reg to read into.
	    emit(o, "RDR " + r); // Read into r.
	    emit(o, "STORE " + r + "," + v + ",0");
	} else if (irt.getOp().equals("CJUMP")) {
	    String lbl = String.valueOf(label);
	    String trueLbl = "t" + lbl;
	    cond(trueLbl, irt.getSub(0), o); // Generate condition code that jumps to trueLbl if true.
	    // Create the jump if false.
	    String falseLbl = "f" + lbl;
	    emit(o, "JMP " + falseLbl);
	    emit(o, trueLbl + ":"); // Mark this as the start of the true branch.
	    statement(irt.getSub(1), o); // Work down the true branch.
	    String endLbl = "e" + lbl;
	    emit(o, "JMP " + endLbl); // Jump at the end of the true block to the end of the if.
	    emit(o, falseLbl + ":"); // Mark this as the start of the false branch.
	    // Don't emit any false body if no else is present!
	    // TODO: Make this more elegant
	    if (irt.subCount() == 3) {
		statement(irt.getSub(2), o); // False branch.
	    }
	    emit(o, endLbl + ":"); // Mark the end of the if.
	} else if (irt.getOp().equals("NOOP")) {
	    // Do we need to output anything here?
	    emit(o, "NOP");
	} else if (irt.getOp().equals("LOOP")) {
	    String lbl = String.valueOf(label);
	    label++;
	    String startLbl = "b" + lbl;
	    String exitLbl = "e" + lbl;
	    emit(o, startLbl + ":"); // Mark the entry of the loop.
	    statement(irt.getSub(0), o); // Loop body. Should run at least once.
	    cond(exitLbl, irt.getSub(1), o); // Until condition. Jumps out if true.
	    emit(o, "JMP " + startLbl); // Jump back if until didn't jump us.
	    emit(o, exitLbl + ":"); // Mark the exit of the loop.
	} else {
	    error(irt.getOp());
	}
    }

    // Generate code from a condition. Returns the label targeted if the condition is true.
    private static void cond(String trueLbl, IRTree irt, PrintStream o) {
	String x = expression(irt.getSub(0), o);
	String y = expression(irt.getSub(1), o);
	String resReg = Reg.newReg();
	switch(irt.getOp()) {
	case "GE":
	    // if x >= y then t = x - y; t >= 0
	    emit(o, "SUBR " + resReg + "," + x + "," + y);
	    emit(o, "BGEZR " + resReg + "," + trueLbl);
	    break;
	case "LT":
	    // if x < y then t = x - y; t < 0
	    emit(o, "SUBR " + resReg + "," + x + "," + y);
	    emit(o, "BLTZR " + resReg + "," + trueLbl);
	    break;
	case "EQ":
	    // if x == y then t = x - y; t == 0
	    emit(o, "SUBR " + resReg + "," + x + "," + y);
	    emit(o, "BEQZR " + resReg + "," + trueLbl);
	    break;
	case "NE":
	    // x-y != 0
	    emit(o, "SUBR " + resReg + "," + x + "," + y);
	    emit(o, "BNEZR " + resReg + "," + trueLbl);
	    break;
	case "GT":
	    // if x > y then t = y - x; t < 0
	    emit(o, "SUBR " + resReg + "," + y + "," + x);
	    emit(o, "BLTZR " + resReg + "," + trueLbl);
	    break;
	case "LE":
	    // if x <= y then t = y - x; t >= 0
	    emit(o, "SUBR " + resReg + "," + y + "," + x);
	    emit(o, "BGEZR " + resReg + "," + trueLbl);
	    break;
	default:
	    error(irt.getOp());
	    break;
	}
    }

    // Generate code from a variable identifier (in IRTree form) TODO: Use I param where possible.
    private static String variable(IRTree irt, PrintStream o) {
	String result = "";
	IRTree sub;
	switch (irt.getOp()) {
	case "MEM":
	    String addr = Memory.lookup(irt.getSub(0).getOp());
	    result = Reg.newReg();
	    emit(o, "MOVIR " + result + "," + addr);
	    sub = irt.getSub(0).tryGetSub(0);
	    if (sub != null) {
		// This is an array.
		String index = expression(sub, o);
		// Need to get index into an address by * 4 + addr
		String four = Reg.newReg(); // TODO: If arrays declared, set aside a "four" reg.
		emit(o, "MOVIR " + four + ",4.0"); // Put 4.0 into Rfour
		emit(o, "MULR " + index + "," + four + "," + index); // Multiply index by 4
		emit(o, "ADDR " + result + "," + index + "," + result); // Add index to addr
	    }
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
