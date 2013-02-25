import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class Program {
    private BufferedReader reader;
    private Database db;

    public Program() {
        InputStreamReader isr = new InputStreamReader(System.in);
        reader = new BufferedReader(isr);

        try {
            db = new Database();
        } catch (Error e) {
            p("Unable to open Database: " + e.getMessage());
            System.exit(1);
        }
    }

    // Print a line
    private void p(String out) {
        System.out.println(out);
    }

    // Print without a newline
    private void query(String out) {
        System.out.print(out);
    }

    private String readln() {
        try {
            return reader.readLine();
        } catch (IOException ioe) {
            throw new Error("Unable to read user input.");
        }
    }

    private void showMainHelp() {
        p("----------------------------------------------------------");
        p("Commands:");
        p("    help            - Display this command list");
        p("    exit            - Exit the program");
        p("    tables          - List tables in the database");
        p("    print <table>   - Display the specified table");
        p("    edit <table>    - Open the specified table for editing");
        p("----------------------------------------------------------");
    }

    private void run() {
        p("DATABASE PROGRAM: By George Field & Alistair Wick");
        p("==========================================================\n");
        showMainHelp();

        while (true) {
            query("\nQuery=>");
            String in = readln();
            String[] splitIn = in.split(" ");
            String cmd = splitIn[0];

            p("");

            if (cmd.equalsIgnoreCase("exit")) {
                break;
            } else if (cmd.equalsIgnoreCase("help")) {
                showMainHelp();
            } else if (cmd.equalsIgnoreCase("tables")) {
                Table[] tables = db.tables();

                p("\nAll tables:");
                for (Table t : tables) {
                    p("    - " + t.name());
                }
            } else if (cmd.equalsIgnoreCase("print")) {
                if (splitIn.length == 2) {
                    Table t = db.table(splitIn[1]);

                    if (t == null) {
                        p("Table " + splitIn[1] + " does not exist.");
                    } else {
                        t.print(System.out);
                    }
                } else {
                    p("Wrong number of arguments.");
                }
            } else if (cmd.equalsIgnoreCase("edit")) {
                if (splitIn.length == 2) {
                    Table t = db.table(splitIn[1]);
                    editTable(t);
                } else {
                    p("Wrong number of arguments.");
                }
            } else {
                p("No such command. Type \"help\" for command list.");
            }
        }

        p("Goodbye.");
    }

    private void showTableHelp() {
        p("----------------------------------------------------------");
        p("Table edit commands:");
        p("    help          - Display this command list");
        p("    done          - Stop editing and save changes to disc");
        p("    print         - Display the open table");
        p("    edit <key>    - Modify record at <key>");
        p("    replace <key> - Replace record at <key>");
        p("    add <key>     - Add a new record with key <key>");
        p("    delete <key>  - Delete record at <key>");
        p("----------------------------------------------------------");
    }

    private void editTable(Table t) {
        if (t == null) {
            p("No such table.");
            return;
        }

        showTableHelp();

        while (true) {
            query("\nEditing " + t.name() + "=>");
            String in = readln();
            String[] splitIn = in.split(" ");
            String cmd = splitIn[0];

            p("");

            if (cmd.equalsIgnoreCase("done")) {
                break;
            } else if (cmd.equalsIgnoreCase("help")) {
                showTableHelp();
            } else if (cmd.equalsIgnoreCase("print")) {
                t.print(System.out);
            } else if (cmd.equalsIgnoreCase("edit")) {
                if (splitIn.length == 2) {
                    editRecord(t, t.select(splitIn[1]));
                } else {
                    p("Wrong number of arguments.");
                }
            } else if (cmd.equalsIgnoreCase("replace")) {
                if (splitIn.length == 2) {
                    replaceRecord(t, t.select(splitIn[1]));
                } else {
                    p("Wrong number of arguments.");
                }
            } else if (cmd.equalsIgnoreCase("delete")) {
                if (splitIn.length == 2) {
                    deleteRecord(t.select(splitIn[1]));
                } else {
                    p("Wrong number of arguments.");
                }
            } else if (cmd.equalsIgnoreCase("add")) {
                if (splitIn.length == 2) {
                    addRecord(t, splitIn[1]);
                }
            } else {
                p("No such command. Type \"help\" for command list.");
            }
        }

        t.store();
        p("Finished editing table: " + t.name());
    }

    private void editRecord(Table t, Record r) {
        if (r == null) {
            p("No such record.");
        } else {
            query("Enter name of column to change: ");
            String col = readln();
            query("Enter new value for field: ");
            String val = readln();

            try {
                String orig = r.field(t.column(col));
                r.field(t.column(col), val);
                p("Changed \"" + orig + "\" to \"" + val + "\".");
            } catch (Error e) {
                p("Unable to modify: " + e.getMessage());
            }
        }
    }

    private void replaceRecord(Table t, Record r) {
        if (r == null) {
            p("No such record.");
        } else {
            String key = r.key();
            r.delete();
            addRecord(t, key);
        }
    }

    private void deleteRecord(Record r) {
        if (r == null) {
            p("No such record.");
        } else {
            r.delete();
            p("Successfully deleted record.");
        }
    }

    private void addRecord(Table t, String key) {
        Record r;

        // Ensure a valid key is used
        try {
            r = new Record(t, key);
        } catch (Error e) {
            p("Unable to add record: " + e.getMessage());
            return;
        }

        // Loop other columns to insert values
        for (int i = 1; i < t.columns(); i++) {
            // Loop to ensure correct type entry
            boolean success = false;
            while (!success) {
                query("Enter value for \"" + t.name(i) + "\": ");
                String val = readln();

                try {
                    r.field(i, val);
                    success = true;
                } catch (Error e) {
                    p("Invalid value \"" + val + "\".");
                }
            }
        }

        t.store();
    }

    public static void main(String[] args) {
        Program p = new Program();
        p.run();
    }
}
