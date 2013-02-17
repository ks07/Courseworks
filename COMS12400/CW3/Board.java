import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

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
        for (int row = 0; row < DIMENSIONS; row++) {
            for (int col = 0; col < DIMENSIONS; col++) {
                grid[row][col] = Player.None;
            }
        }

	turn = Player.X;
        gameState = Player.None;
    }

    public Position position(String s) {
	Matcher match = posRegex.matcher(s);

	if (match.matches()) {
	    int row = letterToIndex(match.group(1));
	    int col = Integer.parseInt(match.group(2));

            // Cols are 1 based to the user, 0 based internally.
            col = col - 1;

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

            // TODO: Delete me
            Position[] p = findPairs(this.turn);
            if (p != null && p.length != 0) {
                println(Arrays.toString(p));
            } else {
                println("No pairs");
            }
        }
    }

    // Returns the empty slot in the horizontal line covering pos, if this is a pair for the player.
    // Returns null if this line is full, contains only 1 mark, or contains both players.
    private Position checkHoriz(Position pos, Player ply) {
        return checkDir(pos.row(), 0, 0, 1, ply);
    }

    private Position checkVert(Position pos, Player ply) {
        return checkDir(0, pos.col(), 1, 0, ply);
    }

    // Returns the empty
    private List<Position> checkDiagonals(Player ply) {
        ArrayList<Position> empty = new ArrayList<Position>();
        Position free = checkDir(0, 0, 1, 1, ply);

        if (free != null) {
            empty.add(free);
        }
        
        free = checkDir(0, 2, 1, -1, ply);
        
        if (free != null) {
            empty.add(free);
        }

        return empty;
    }

    private boolean checkBounds(int row, int col) {
        return row >= 0 && col >= 0 && row < DIMENSIONS && col < DIMENSIONS;
    }

    private Position checkDir(int row, int col, int rD, int cD, Player ply) {
        int count = 0;
        Position empty = null;

        for (; checkBounds(row, col); row = row + rD) {
            if (grid[row][col] == ply) {
                count++;
            } else if (grid[row][col] == ply.other()) {
                return null;
            } else {
                empty = new Position(row, col);
            }

            col = col + cD;
        }

        if (count == 2) {
            return empty;
        } else {
            return null;
        }
    }

    // Finds the first empty spot from a position horiz or vertically.
    // Returns null if neither contain a suitable pair.
    private List<Position> findPairsFromPos(Position pos, Player ply) {
        ArrayList<Position> empty = new ArrayList<Position>();
        Position free = checkHoriz(pos, ply);

        if (free != null) {
            empty.add(free);
        }

        free = checkVert(pos, ply);

        if (free != null) {
            empty.add(free);
        }

        return empty;
    }

    // Finds the first empty spot suitable for a pair for the given player.
    // Returns null if all are empty.
    private Position[] findPairs(Player ply) {
        int row = 0, col = 0;
        List<Position> empty = null;

        for (; row < DIMENSIONS; row++) {
            if (empty == null || empty.isEmpty()) {
                empty = findPairsFromPos(new Position(row, col), ply);
            } else {
                empty.addAll(findPairsFromPos(new Position(row, col), ply));
            }

            col++;
        }

        if (empty == null || empty.isEmpty()) {
            empty = checkDiagonals(ply);
        } else {
            empty.addAll(checkDiagonals(ply));
        }

        return empty.toArray(new Position[0]);
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

        for (int row = 0; row < DIMENSIONS; row++) {
            switch (row) {
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

            for (int col = 0; col < DIMENSIONS; col++) {
                switch (grid[row][col]) {
                case X:
                    sb.append(" X");
                    break;
                case O:
                    sb.append(" O");
                    break;
                default:
                    if (col < DIMENSIONS - 1) {
                        sb.append("  ");
                    }
                }

                if (col < DIMENSIONS - 1) {
                    sb.append(" |");
                }
            }

            sb.append('\n');

            if (row < DIMENSIONS - 1) {
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