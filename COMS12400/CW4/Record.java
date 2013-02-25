public class Record {
    private String[] fields;
    private final Table parent;

    public Record(Table table, String key) {
        parent = table;

        // Check the key isn't in use
        if (parent.select(key) != null) {
            throw new Error("Key already in use.");
        }

        // Determine number of columns to use and
        // insert if the table already has a header
        int cols;
        if (parent.columns() == 0) {
            cols = 1;
        } else {
            cols = parent.columns();
        }

        fields = new String[cols];
        field(0, key);

        // Fill with blank strings
        for (int i = 1; i < cols; i++) {
            field(i, "");
        }

        parent.insert(this);
    }

    public Record(Table table, String[] values) {
        parent = table;

        // Check that the array is valid
        if (values == null) {
            throw new Error("Attempted to store a null value.");
        }

        // Check that no array elements are null.
        for (String s : values) {
            if (s == null) {
                throw new Error("Attempted to store a null value.");
            }
        }

        // Check the key isn't in use
        if (parent.select(values[0]) != null) {
            throw new Error("Key already in use.");
        }

        // Check the array fits into table
        if (parent.columns() != 0 && values.length > parent.columns()) {
            throw new Error("Record length exceeds table size.");
        }

        // Determine number of columns to use and
        // insert if the table already has a header
        int cols;
        if (parent.columns() == 0) {
            cols = values.length;
        } else {
            cols = parent.columns();
        }

        fields = new String[cols];

        // Copy the provided array so that it cannot be modified externally.
        System.arraycopy(values, 0, fields, 0, values.length);

        // Fill in the remainder with blanks
        for (int i = values.length; i < cols; i++) {
            field(i, "");
        }

        parent.insert(this);
    }

    private boolean checkBounds(int col) {
        return col >= 0 && col < fields.length;
    }

    public String field(int col) {
        if (checkBounds(col)) {
            return fields[col];
        } else {
            throw new Error("Bad column.");
        }
    }

    public void field(int col, String value) {
        if (checkBounds(col)) {
            if (value != null) {
                if (col == 0 && parent.select(value) != null) {
                    throw new Error("Key already in use.");
                }

                Type type = parent.type(col);

                if (!type.allowed(value)) {
                    throw new Error("Value not of type " + type.toString());
                }

                fields[col] = value;
            } else {
                throw new Error("Attempted to store a null value.");
            }
        } else {
            throw new Error("Bad column.");
        }
    }

    public int fields() {
        return fields.length;
    }

    public String key() {
        if (fields.length > 0) {
            return fields[0];
        } else {
            throw new Error("Bad column.");
        }
    }

    public void delete() {
        if (fields == null) {
            throw new Error("Record has already been deleted.");
        }

        if (parent.select(key()) != null) {
            fields = null;
            parent.delete(this);
        } else {
            throw new Error("Attempted to delete header.");
        }
    }

    public static void main(String[] args) {
        // Do some tests.
        String[] cols = {
            "Key",
            "A",
            "B",
            "C",
            "D"
        };
        String[] values = {
            "alpha",
            "beta",
            "gamma",
            "delta",
            "epsilon"
        };

        Database db = new Database();
        Table t = new Table(db, "test", cols);
        Record r = new Record(t, values);

        if (r.checkBounds(-1)) {
            throw new Error("Bounds check failed.");
        }
        if (r.fields() != values.length) {
            throw new Error("Fields incorrect.");
        }
        if (!values[0].equals(r.field(0))) {
            throw new Error("Field get incorrect.");
        }

        r.field(0, "apple");
        if (!"apple".equals(r.field(0))) {
            throw new Error("Field set failed.");
        }

        if (!t.select("apple").equals(r)) {
            throw new Error("Record not in table.");
        }

        r.delete();
        if (t.select("apple") != null) {
            throw new Error("Deleted record still in table.");
        }

        Record r1 = new Record(t, values);
        r1.field(0, "apple");
        Record r2 = new Record(t, values);
        r2.field(0, "endothermic");
        Record r3 = new Record(t, values);
        r3.field(0, "To Kill a Mockingbird");

        r3.delete();

        boolean fail = true;

        try {
            r3.field(0, "Ditto");
        } catch (Error e) {
            fail = false;
        } catch (NullPointerException npe) {
            fail = false;
        } finally {
            if (fail) {
                throw new Error("Deleted record still functional.");
            }
        }
    }
}
