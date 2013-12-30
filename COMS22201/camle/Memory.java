import java.util.ArrayList;
import java.io.*;

public class Memory {

    static int stringID = 0;
    static ArrayList<Byte> memory = new ArrayList<Byte>();

    static public int allocateString(String text)
    {
	int id = stringID++; // Store a string with a unique identifier, per string and per byte.
	int subId = 0;
	int addr = memory.size();
	int size = text.length();
	for (int i=0; i<size; i++) {
	    memory.add(new Byte(id, subId++, text.charAt(i)));
	}
	memory.add(new Byte(id, subId++, 0));
	return addr;
    }

    static public void dumpData(PrintStream o)
    {
	Byte b;
	String s;
	int c;
	int size = memory.size();
	for (int i=0; i<size; i++) {
	    b = memory.get(i);
	    c = b.getContents();
	    if (c >= 32) {
		s = String.valueOf((char)c);
	    }
	    else {
		s = ""; // "\\"+String.valueOf(c);
	    }
	    o.println("DATA "+c+" ; "+s+" "+b.getName());
	}
    }
}

class Byte {
    String varname;
    int contents;

    // Construct a Byte that forms a string.
    Byte(int sId, int bId, int c) {
	varname = sId+"-"+bId; // Use a special name for strings, based on IDs.
	contents = c;
    }

    Byte(String n, int c)
    {
	if (!n.isEmpty() && Character.isDigit(n.charAt(0))) {
	    System.out.println("WARNING: Defined variable with reserved name ("+n+")! This shouldn't be possible!");
	}
	varname = n;
	contents = c;
    }

    String getName()
    {
	return varname;
    }

    int getContents()
    {
	return contents;
    }
}
