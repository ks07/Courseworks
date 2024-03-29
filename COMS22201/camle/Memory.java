import java.util.ArrayList;
import java.util.HashMap;
import java.io.*;

public class Memory {

    private static int stringID = 0;
    // We could use a LinkedHashMap here to combine id and address based access.
    // Problem is, being based on a LinkedList means index based access is inefficient.
    // Let's just do it ourselves.
    static HashMap<String, Integer> memoryLookup = new HashMap<String, Integer>();
    static ArrayList<Byte> memory = new ArrayList<Byte>();

    static HashMap<String, Integer> stringLookup = new HashMap<String, Integer>();

    static public int allocateArray(String id, int size) {
	int addr = memory.size();
	assert (addr % 4) == 0;

	if (size > 0) {
	    memoryLookup.put(id, addr);
	    for (size = size * 4; size > 0; size--) {
		memory.add(new Byte(id));
	    }
	} else {
	    System.err.println("Warning: 0 length array declared!");
	    memoryLookup.put(id, -1);
	}

	assert (memory.size() % 4) == 0;
	return addr;
    }

    static public int allocateString(String text)
    {
	Integer a = stringLookup.get(text);

	if (a == null) {
	    int id = stringID++;
	    int addr = memory.size();
	    int size = text.length();

	    assert (addr % 4) == 0;

	    // Only store the address of the first char of the string in lookup.
	    stringLookup.put(text, addr);
	    Byte nextC = new Byte(id, text.charAt(0));
	    memory.add(nextC);
	
	    for (int i=1; i<size; i++) {
		nextC = new Byte(id, text.charAt(i));
		memory.add(nextC);
	    }
	    nextC = new Byte(id, 0);
	    memory.add(nextC);
	    // Make sure we end on 4 byte boundaries, as the machine can only access from these points.
	    int padding = 4 - (memory.size() % 4);
	    if (padding != 4) {
		// When padding == 4, none is required.
		for (; padding > 0; padding--) {
		    memory.add(new Byte(id, 0));
		}
	    }
	    return addr;
	} else {
	    // Strings are immutable in the language, so we can reuse old allocations.
	    return a.intValue();
	}
    }

    // Allocate the next 4 byte chunk for a variable. Zero contents.
    static public int alloc(String id) {
	// Check if this named value exists already.
	Integer addr = memoryLookup.get(id);
	if (addr == null) {
	    // New value.
	    addr = memory.size();
	    assert (addr % 4) == 0;
	    int size = 4; // Reals are 4 bytes.
	    memoryLookup.put(id, addr);
	    for (int i = 0; i < size; i++) {
		memory.add(new Byte(id, 0));
	    }
	}

	return addr.intValue();
    }

    public static String lookup(String id) {
	// Operand must be formatted as a double.
	return memoryLookup.get(id) + ".0"; //TODO: Error messages if not present/invalid?
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

    // Constructor for 0 value.
    Byte(String n) {
	varname = n;
	contents = 0;
    }

    // Construct a Byte that forms a string.
    Byte(int sId, int c) {
	varname = sId+"_STRING"; // Use a special name for strings, based on IDs.
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
