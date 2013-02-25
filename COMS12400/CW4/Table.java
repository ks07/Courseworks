import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.security.DigestInputStream;
import java.security.DigestOutputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;

public class Table {
    private final String name;
    private final Record header;
    private final Type[] types;
    private final ArrayList<Record> records;
    private final Database parent;

    private static final Type[] defaultTypes(Database db, int cols) {
        // Set type to default, String.
        Type[] types = new Type[cols];
        Type strType = Type.type(db, "string");
        Arrays.fill(types, strType);

        return types;
    }

    public Table(Database db, String name, String[] columns) {
        this(db, name, columns, defaultTypes(db, columns.length));
    }

    public Table(Database db, String name, String[] columns, Type[] types) {
        records = new ArrayList<Record>();
        this.name = name;
        header = new Record(this, columns);
        this.types = types;
        parent = db;
        parent.addTable(this);
    }

    public Table(Database db, String name) {
        records = new ArrayList<Record>();
        this.name = name;

        try {
            File inFile = new File(name + ".txt");
            BufferedReader in = new BufferedReader(new FileReader(inFile));
            String[] line = readNext(in);

            if (line != null) {
                // First line gives the column names.
                header = new Record(this, line);
            } else {
                throw new Error("Table file empty.");
            }

            line = readNext(in);
            if (line != null && line.length == header.fields()) {
                // Second line gives the column types.
                types = new Type[header.fields()];
                for (int i = 0; i < line.length; i++) {
                    Type t = Type.type(db, line[i]);
                    types[i] = t;
                }
            } else {
                throw new Error("Types not present for columns.");
            }

            for (line = readNext(in); line != null; line = readNext(in)) {
                if (line.length == header.fields()) {
                    new Record(this, line);
                } else {
                    throw new Error("Table file invalid.");
                }
            }
        } catch (IOException ioe) {
            throw new Error("Could not read table file.", ioe);
        }

        parent = db;
        parent.addTable(this);
    }

    // Reads the next record from the given BufferedReader as an array of Strings.
    // Returns null if there are no more lines.
    private static String[] readNext(BufferedReader in) throws IOException {
        ArrayList<String> ret = new ArrayList<String>();
        StringBuilder sb = new StringBuilder();
        int read = in.read();
        boolean isEscaped = false;
        char c;

        while (read >= 0) {
            c = (char)read;

            if (c == '\r') {
                // Skip it
                read = in.read();
                c = (char)read;
            }

            if (isEscaped) {
                if (c == ',' || c == '\\' || c == '\n') {
                    // Met a valid escape sequence, append.
                    sb.append(c);
                } else {
                    // Found an invalid escape sequence (e.g. \a).
                    throw new Error("Table file invalid.");
                }

                isEscaped = false;
            } else if (c == '\\') {
                // Met an escape character, ignore and set state.
                isEscaped = true;
            } else if (c == ',') {
                // Met a field delimiter, add to the list.
                ret.add(sb.toString());

                // Reset the StringBuilder.
                sb = new StringBuilder();
            } else if (c == '\n') {
                // Met a record delimiter, add & return the array.
                ret.add(sb.toString());
                return ret.toArray(new String[ret.size()]);
            } else {
                // Found a regular character, append.
                sb.append(c);
            }

            read = in.read();
        }

        // Return null if we get to EOF without a newline.
        return null;
    }

    public void store() {
        try {
            BufferedWriter out = new BufferedWriter(new FileWriter(this.name + ".txt"));

            // Write the header.
            String s;
            for (int col = 0; col < header.fields() - 1; col++) {
                s = header.field(col);
                out.write(escapeChars(s));
                out.write(',');
            }
            s = header.field(header.fields() - 1);
            out.write(escapeChars(s));
            out.write('\n');

            // Write the types.
            for (int i = 0; i < types.length - 1; i++) {
                s = types[i].toString();
                out.write(escapeChars(s));
                out.write(',');
            }
            s = types[types.length - 1].toString();
            out.write(escapeChars(s));
            out.write('\n');

            for (Record r : this.records) {
                for (int f = 0; f < r.fields() - 1; f++) {
                    s = r.field(f);
                    out.write(escapeChars(s));
                    out.write(',');
                }
                s = r.field(r.fields() - 1);
                out.write(escapeChars(s));
                out.write('\n');
            }

            out.close();
        } catch (IOException ioe) {
            throw new Error("Failed to write table file.", ioe);
        }
    }

    private static String escapeChars(String field) {
        String ret = field;

        // Replace all single \ with double \\.
        ret = ret.replace("\\", "\\\\");

        // Precede all newlines and commas with a \.
        ret = ret.replace("\n", "\\\n");
        ret = ret.replace(",", "\\,");

        return ret;
    }

    public String name() {
        return name;
    }

    public int rows() {
        return records.size();
    }

    public int columns() {
        if (header == null) {
            return 0;
        } else {
            return header.fields();
        }
    }

    public String name(int col) {
        if (checkColBounds(col)) {
            return header.field(col);
        } else {
            throw new Error("Bad column.");
        }
    }

    public int column(String name) {
        for (int col = 0; col < header.fields(); col++) {
            if (header.field(col).equalsIgnoreCase(name)) {
                return col;
            }
        }

        return -1;
    }

    public Type type(int col) {
        if (checkColBounds(col)) {
            return types[col];
        } else {
            throw new Error("Bad column.");
        }
    }

    public Record select(int row) {
        if (checkRowBounds(row)) {
            return records.get(row);
        } else {
            throw new Error("Bad row.");
        }
    }

    public Record select(String key) {
        for (int i = 0; i < records.size(); i++) {
            Record r = records.get(i);
            if (r.key().equals(key)) {
                return r;
            }
        }

        return null;
    }

    protected void insert(Record r) {
        // Do nothing if there's no header
        if (header == null) {
            return;
        } else if (find(r) < 0) {
            if (checkRecord(r)) {
                records.add(r);
            } else {
                throw new Error("Field invalid for given type.");
            }
        } else {
            throw new Error("Inserting duplicate record.");
        }
    }

    // Returns true if all the fields in the given record fit with the type.
    private boolean checkRecord(Record r) {
        for (int i = 0; i < r.fields(); i++) {
            if (!types[i].allowed(r.field(i))) {
                return false;
            }
        }

        return true;
    }

    protected void delete(Record r) {
        int row = find(r);

        if (row >= 0) {
            records.remove(row);
        } else {
            throw new Error("Deleting non-existant record.");
        }
    }

    private int find(Record r) {
        for (int row = 0; row < records.size(); row++) {
            if (records.get(row) == r) {
                return row;
            }
        }

        return -1;
    }

    private boolean checkRowBounds(int row) {
        return row >= 0 && row < records.size();
    }

    private boolean checkColBounds(int col) {
        return col >= 0 && col < header.fields();
    }

    public void print(PrintStream out) {
        int[] widths = getColWidths();

        for (int col = 0; col < widths.length - 1; col++) {
            String val = header.field(col);
            out.print(val);
            printMult(out, ' ', widths[col] - val.length());
            out.print("| ");
        }
        out.println(header.field(widths.length - 1));

        for (int col = 0; col < widths.length - 1; col++) {
            printMult(out, '-', widths[col]);
            out.print("+-");
        }
        printMult(out, '-', widths[widths.length - 1] - 1);
        out.println();

        for (Record r : records) {
            for (int col = 0; col < widths.length - 1; col++) {
                padPrint(out, r.field(col), col, widths[col]);
            }
            int col = widths.length - 1;
            padPrint(out, r.field(col), col, widths[col]);
        }
    }

    private void padPrint(PrintStream out, String val, int col, int len) {
        if (types[col].toString().equals("integer")) {
            printMult(out, ' ', len - val.length() - 1);
            out.print(val);
            if (col != (header.fields() - 1)) {
                out.print(" ");
            }
        } else {
            out.print(val);
            printMult(out, ' ', len - val.length());
        }

        if (col != columns()-1) {
            out.print("| ");
        } else {
            out.print("\n");
        }
    }

    private void printMult(PrintStream out, char c, int len) {
        for (; len >= 0; len--) {
            out.print(c);
        }
    }

    private int[] getColWidths() {
        int[] widths = new int[header.fields()];

        for (int col = 0; checkColBounds(col); col++) {
            widths[col] = getColWidth(col);
        }

        return widths;
    }

    private int getColWidth(int col) {
        int width = header.field(col).length();

        for (Record r : records) {
            if (r.field(col).length() > width) {
                width = r.field(col).length();
            }
        }

        return width;
    }

    public static void main(String[] args) {
        String[] cols = {
            "alpha",
            "Beta\nNewline",
            "gamma"
        };

        Database db = new Database();
        Table t = new Table(db, "test", cols);
        new Record(t, new String[] {"a", "b", "c"});
        new Record(t, new String[] {"ab\ncd", "ef\\gh", "ij,kl"});
        new Record(t, new String[] {"1", "2", "3"});

        if (!"2".equals(t.select("1").field(1))) {
            throw new Error("Key incorrect");
        }

        // Store in a file.
        t.store();

        // Test loading of the file.
        t = new Table(db, "test");

        if (t.columns() != cols.length) {
            throw new Error("Columns incorrect.");
        }
        if (!"test".equals(t.name())) {
            throw new Error("Name incorrect.");
        }
        if (!cols[1].equals(t.name(1))) {
            throw new Error("Column name incorrect.");
        }

        t = new Table(db, "people");

        try {
            FileOutputStream fos = new FileOutputStream(new File("print_test_out.out"));
            MessageDigest outDigest = MessageDigest.getInstance("MD5");
            DigestOutputStream outDigestStream = new DigestOutputStream(fos, outDigest);
            PrintStream testOut = new PrintStream(outDigestStream);
            t.print(testOut);
            testOut.close();
            FileInputStream fis = new FileInputStream(new File("print_test_comp.out"));
            MessageDigest inDigest = MessageDigest.getInstance("MD5");
            DigestInputStream inDigestStream = new DigestInputStream(fis, inDigest);

            int r = inDigestStream.read();
            while (r != -1) {
                r = inDigestStream.read();
            }

            if (!Arrays.equals(outDigest.digest(), inDigest.digest())) {
                throw new Error("Print output does not match expected output.");
            }
        } catch (IOException ioe) {
            throw new Error("Print testing failed.", ioe);
        } catch (NoSuchAlgorithmException nsa) {
            throw new Error("Print test algorithm doesn't exist.");
        }
    }
}
