import java.io.File;
import java.io.FileFilter;
import java.util.Collection;
import java.util.HashMap;

public class Database {
    private final HashMap<String, Table> tables;

    public Database() {
        File dataDir = new File(".");
        tables = new HashMap<String, Table>();

        for (File tbl : dataDir.listFiles(new TableFilter())) {
            int end = tbl.getName().length() - 4;
            String name = tbl.getName().substring(0, end);

            new Table(this, name);
        }
    }

    public Table table(String name) {
        return tables.get(name);
    }

    public Table[] tables() {
        Table[] result = new Table[0];
        Collection<Table> c = tables.values();
        return c.toArray(result);
    }

    // Internal method for use by table constructors
    void addTable(Table t) {
        tables.put(t.name(), t);
    }

    private static class TableFilter implements FileFilter {
        public boolean accept(File file) {
            return file.isFile() && file.canRead() && !file.isHidden()
                && file.getName().endsWith(".txt");
        }
    }

    public static void main(String[] args) {
        Database db = new Database();
        Table t = db.table("people");

        if (t == null) {
            throw new Error("People table missing from database.");
        }
    }
}
