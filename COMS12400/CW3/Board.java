import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.ArrayList;

public class Board {

    private static final int DIMENSIONS = 3;

    private final Pattern posRegex;
    // grid[row][col] / grid[y][x]
    public final Player[][] grid;

    private Player turn;
    private Player gameState;

    public Board() {
	posRegex = Pattern.compile("([abc])([123])");
	grid = new Player[DIMENSIONS][DIMENSIONS];

        // Initialise the grid.
        for (int i = 0; i < DIMENSIONS; i++) {
            for (int j = 0; j < DIMENSIONS; j++) {
                grid[i][j] = Player.None;
            }
        }

	turn = Player.X;
        gameState = Player.None;
    }

    public Position position(String s) {
	Matcher match = posRegex.matcher(s);

	if (match.matches()) {
	    int col = letterToIndex(match.group(1));
	    int row = Integer.parseInt(match.group(2));

            // Rows are 1 based to the user, 0 based internally.
            row = row - 1;

	    Position ret = new Position(row, col);

            if (isOccupied(ret)) {
                // The space is not free, return null.
                return null;
            } else {
                return ret;
            }
	} else {
	    return null;
	}
    }

    public void move(Position pos) {
        if (this.turn == Player.X || this.turn == Player.O) {
            grid[pos.row()][pos.col()] = this.turn;

            // Switch to the next players turn.
            this.turn = this.turn.other();
        }
    }

    // Returns the empty slot in the horizontal line covering pos, if this is a pair for the player.
    // Returns null if this line is full, contains only 1 mark, or contains both players.
    private Position checkHoriz(Position pos, Player ply) {
        int col, count = 0;
        Position empty = null;

        for (col = 0; col < DIMENSIONS; col++) {
            if (grid[pos.row()][col] == ply) {
                count++;
            } else if (grid[pos.row()][col] == ply.other()) {
                return null;
            } else {
                empty = new Position(pos.row(), col);
            }
        }

        if (count == 2) {
            return empty;
        } else {
            return null;
        }
    }

    private Position checkVert(Position pos, Player ply) {
        int row, count = 0;
        Position empty = null;

        for (row = 0; row < DIMENSIONS; row++) {
            if (grid[row][pos.col()] == ply) {
                count++;
            } else if (grid[row][pos.col()] == ply.other()) {
                return null;
            } else {
                empty = new Position(row, pos.col());
            }
        }

        if (count == 2) {
            return empty;
        } else {
            return null;
        }
    }

    // Finds the first empty spot from a position horiz or vertically.
    // Returns null if neither contain a suitable pair.
    private Position findPairFromPos(Position pos, Player ply) {
        Position empty = checkHoriz(pos, ply);

        if (empty != null) {
            return empty;
        } else {
            empty = checkVert(pos, ply);
            return empty;
        }
    }

    // Finds the first empty spot suitable for a pair for the given player.
    // Returns null if all are empty.
    private Position findPair(Player ply) {
        int row = 0, col = 0;
        Position empty;

        for (; row < DIMENSIONS; row++) {
            empty = findPairFromPos(new Position(row, col), ply);

            if (empty != null) {
                return empty;
            }

            col++;
        }

        // If we haven't returned yet, the only remaining possible spots are diagonals.
        return checkDiagonals(ply);
    }

    // Returns the empty 
    private Position checkDiagonals(Player ply) {
        int row, col = 0, count = 0;
        Position empty = null;

        for (row = 0; row < DIMENSIONS; row++) {
            if (grid[row][col] == ply) {
                count++;
            } else if (grid[row][col] == ply.other()) {
                return null;
            } else {
                empty = new Position(row, col);
            }

            col++;
        }

        if (count == 2) {
            return empty;
        } else {
            col = 2;

            for (row = 0; row < DIMENSIONS; row++) {
                if (grid[row][col] == ply) {
                    count++;
                } else if (grid[row][col] == ply.other()) {
                    return null;
                } else {
                    empty = new Position(row, col);
                }

                col--;
            }

            if (count == 2) {
                return empty;
            } else {
                return null;
            }
        }
    }

    public Player winner() {
        int r, c;
        Player curr;

        // Check vertical.
        for (r = 0; r < DIMENSIONS; r++) {
            curr = grid[r][0];

            if (curr == Player.X || curr == Player.O) {
                for (c = 1; c < DIMENSIONS; c++) {
                    if (curr != grid[r][c]) {
                        curr = Player.None;
                    }
                }

                if (curr == Player.X || curr == Player.O) {
                    // Found a vertical line, return the player.
                    return curr;
                }
            }
        }

        // Check horizontal.
        for (c = 0; c < DIMENSIONS; c++) {
            curr = grid[0][c];

            if (curr == Player.X || curr == Player.O) {
                for (r = 1; r < DIMENSIONS; r++) {
                    if (curr != grid[r][c]) {
                        curr = Player.None;
                    }
                }

                if (curr == Player.X || curr == Player.O) {
                    // Found a vertical line, return the player.
                    return curr;
                }
            }
        }

        // Check diagonal.
        curr = grid[0][0];
        c = 1;
        for (r = 1; r < DIMENSIONS; r++) {
            if (curr != grid[r][c]) {
                curr = Player.None;
            }

            c++;
        }
        if (curr == Player.X || curr == Player.O) {
            // Found a vertical line, return the player.
            return curr;
        }

        curr = grid[0][2];
        r = 1;
        c = 1;
        while (r < DIMENSIONS) {
            if (curr != grid[r][c]) {
                curr = Player.None;
            }

            r++;
            c--;
        }
        if (curr == Player.X || curr == Player.O) {
            // Found a vertical line, return the player.
            return curr;
        }

        if (blanks().length == 0) {
            return Player.Both;
        } else {
            return Player.None;
        }
    }

    public Position[] blanks() {
        ArrayList<Position> arr = new ArrayList<Position>();

        for (int i = 0; i < DIMENSIONS; i++) {
            for (int j = 0; j < DIMENSIONS; j++) {
                if (grid[i][j] == Player.None) {
                    arr.add(new Position(i, j));
                }
            }
        }

        return arr.toArray(new Position[0]);
    }

    public Position suggest() {
        return null;
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();

        sb.append("     1   2   3\n\n");

        for (int i = 0; i < DIMENSIONS; i++) {
            switch (i) {
            case 0:
                sb.append(" a  ");
                break;
            case 1:
                sb.append(" b  ");
                break;
            case 2:
                sb.append(" c  ");
                break;
            }

            for (int j = 0; j < DIMENSIONS; j++) {
                switch (grid[j][i]) {
                case X:
                    sb.append(" X");
                    break;
                case O:
                    sb.append(" O");
                    break;
                default:
                    if (j < DIMENSIONS - 1) {
                        sb.append("  ");
                    }
                }

                if (j < DIMENSIONS - 1) {
                    sb.append(" |");
                }
            }

            sb.append('\n');

            if (i < DIMENSIONS - 1) {
                sb.append("    ---+---+---\n");
            }
        }

        return sb.toString();
    }

    private boolean isOccupied(Position pos) {
        switch (grid[pos.row()][pos.col()]) {
        case X:
        case O:
            return true;
        default:
            return false;
        }
    }

    private int letterToIndex(String l) {
	char val = l.toLowerCase().charAt(0);

	return val - 97;
    }

    public static void main(String[] args) {
	// Run tests.
	Board b = new Board();

        b.move(b.position("a2"));
        b.move(b.position("a3"));
        b.move(b.position("b1"));
        b.move(b.position("b2"));


        b.grid[1][2] = Player.O;

        println(b.toString());
        if ("     1   2   3\n\n a     | X | O\n    ---+---+---\n b   X | O |\n    ---+---+---\n c     | O |\n".equals(b.toString())) {
            println("yes");
        } else {
            println("no");
        }

        println(b.winner().toString());
    }

    public static void println(String s) {
	System.out.println(s);
    }
}