import java.util.HashMap;
import java.util.HashSet;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class Type {
    // Map database and names to type objects. Ref will need an object per db and table.
    private static final HashMap<TypeKey, Type> typeCache = new HashMap<TypeKey, Type>();

    // One or more strings not containing ',' separated with ,
    private static final Pattern TAGPAT = Pattern.compile("[^,]+(,[^,]+)*");
    private static final Pattern INTPAT = Pattern.compile("-?[0-9]+");

    private final TYPE type;
    private final HashSet<String> tags;
    private final Table ref;
    private final String name;

    // Private constructor for internal use
    private Type(String name, TYPE type, String[] tags, Table ref) {
        this.name = name;
        this.type = type;

        if (tags != null) {
            this.tags = new HashSet<String>();

            for (String tag : tags) {
                // Add returns false if the element already exists.
                if (!this.tags.add(tag)) {
                    throw new Error("Duplicate tag.");
                }
            }
        } else {
            this.tags = null;
        }

        this.ref = ref;
    }

    public boolean allowed(String value) {
        // Can never be a null value
        if (value == null) {
            throw new Error("Attempted to check null value.");
        }
        
        // Always allow blank
        if (value == "") {
            return true;
        }
        
        // Otherwise test
        switch (type) {
        case STR:
            return true;
        case INT:
            return INTPAT.matcher(value).matches();
        case TAG:
            return tags.contains(value);
        case REF:
            return ref.select(value) != null;
        }

        throw new Error("Could not check value against type.");
    }

    public static Type type(Database db, String name) {
        TYPE parsed = parseName(name);
        TypeKey key = new TypeKey(db, parsed, name);
        Type ret = typeCache.get(key);

        // If not cached, create new.
        if (ret == null) {
            switch (parsed) {
            case STR:
            case INT:
                ret = new Type(name, parsed, null, null);
                break;
            case REF:
                Table ref = db.table(name.substring(4, name.length() - 1));

                if (ref != null) {
                    ret = new Type(name, parsed, null, ref);
                } else {
                    throw new Error("Type references non-existant table.");
                }
                break;
            case TAG:
                String inner = name.substring(4, name.length() - 1);
                Matcher m = TAGPAT.matcher(inner);

                if (m.matches()) {
                    String[] tags = inner.split(",");
                    ret = new Type(name, parsed, tags, null);
                } else {
                    throw new Error("Type tags are invalid.");
                }
                break;
            }

            typeCache.put(key, ret);
        }

        return ret;
    }

    boolean rightAligned() {
        return type == TYPE.INT;
    }

    private static TYPE parseName(String name) {
        if ("string".equals(name)) {
            return TYPE.STR;
        } else if ("integer".equals(name)) {
            return TYPE.INT;
        } else if (name.length() > 5) {
            if (name.startsWith("ref(") && name.endsWith(")")) {
                return TYPE.REF;
            } else if (name.startsWith("tag(") && name.endsWith(")")) {
                return TYPE.TAG;
            }
        }

        throw new Error("Invalid type name: " + name);
    }

    public String toString() {
        return this.name;
    }

    public static void main(String[] args) {
        Database db = new Database();
        Type str0 = type(db, "string");
        Type int0 =  type(db, "integer");
        Type ref0 = type(db, "ref(people)");
        Type tag0 = type(db, "tag(yes,no)");
        Type tag1 = type(db, "tag(yes,no)");

        if (tag0 != tag1) {
            throw new Error("Did not retrieve tag from cache.");
        }
        if (!tag0.allowed("yes")) {
            throw new Error("Tag allowed failed.");
        }
        if (tag0.allowed("maybe")) {
            throw new Error("Invalid tag accepted.");
        }

        boolean dupErr = true;

        try {
            // This should cause an error.
            Type dup0 = type(db, "tag(yes,no,maybe,yes)");
            dupErr = false;
        } catch (Error e) {
        }

        if (!dupErr) {
            throw new Error("Duplicate tags accepted.");
        }
    }

    private enum TYPE {
        STR, INT, TAG, REF;
    }

    private static class TypeKey {
        private final Database db;
        private final String name;

        public TypeKey(Database db, TYPE type, String name) {
            this.name = name;

            // Db is only relevant if this is a ref type.
            if (type == TYPE.REF) {
                this.db = db;
            } else {
                this.db = null;
            }
        }

        public int hashCode() {
            // Try and avoid collisions.
            if (db == null) {
                return name.hashCode();
            } else {
                // TODO: Possible improvements?
                return (db.toString() + name).hashCode();
            }
        }

        public boolean equals(Object obj) {
            if (obj == null) {
                return false;
            } else if (obj == this) {
                return true;
            } else if (!(obj instanceof TypeKey)) {
                return false;
            } else {
                TypeKey other = (TypeKey)obj;
                boolean dbEquals = (db == null && other.db == null) || db.equals(other.db);
                return dbEquals && name.equals(other.name);
            }
        }
    }
}
