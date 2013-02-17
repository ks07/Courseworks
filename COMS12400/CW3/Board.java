import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.List;
import java.util.ArrayList;

public class Board {
    private static final int ROWS = 3;
    private static final int COLS = 3;
    private final Pattern posRegex = Pattern.compile("([abc])([123])");
    private final Player[][] grid;
    private Player turn;

    public Board() {
        grid = new Player[ROWS][COLS];

        // Initialise the grid.
        for (int row = 0; row < ROWS; row++) {
            for (int col = 0; col < COLS; col++) {
                grid[row][col] = Player.None;
            }
        }

        turn = Player.X;
    }

    private Board(Player[][] orig, Player first) {
        grid = orig;
        turn = first;
    }

    public Position position(String s) {
        Matcher match = posRegex.matcher(s);

        if (match.matches()) {
            int row = letterToIndex(match.group(1));
            // Cols are 1 based to the user, 0 based internally.
            int col = Integer.parseInt(match.group(2)) - 1;
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

    // Returns the empty slot in the horizontal line covering pos with a pair.
    // Returns null if this does not contain exactly 2 marks for the player.
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
        return row >= 0 && col >= 0 && row < ROWS && col < COLS;
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

        for (; checkBounds(row, col); row++) {
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

        return empty.toArray(new Position[empty.size()]);
    }

    // Returns true if the given player has a fork. (2 or more win conditions)
    private boolean hasFork(Player ply) {
        Position[] pairs = findPairs(ply);
        return pairs.length > 1;
    }

    private Player[][] copyGrid() {
        Player[][] newGrid = new Player[ROWS][COLS];

        for (int row = 0; row < ROWS; row++) {
            for (int col = 0; col < COLS; col++) {
                newGrid[row][col] = grid[row][col];
            }
        }

        return newGrid;
    }

    // Returns the position to play on to create a fork for the given player.
    private Position tryFork(Player ply) {
        // Brute force this step, try each possible next move.
        Board trial;
        Player[][] newGrid;

        for (Position pos : blanks()) {
            newGrid = copyGrid();
            newGrid[pos.row()][pos.col()] = ply;

            trial = new Board(newGrid, ply.other());
            if (trial.hasFork(ply)) {
                return pos;
            }
        }

        return null;
    }

    public Player checkWinnerDir(int row, int col, int rD, int cD) {
        Player ply, prev = grid[row][col];

        row = row + rD;
        col = col + cD;

        if (prev == Player.X || prev == Player.O) {
            for (; checkBounds(row, col); row = row + rD) {
                ply = grid[row][col];

                if (ply != prev) {
                    return Player.None;
                }

                col = col + cD;
            }

            return prev;
        } else {
            return Player.None;
        }
    }

    private Player checkWinnerFromPos(int row, int col) {
        // Look horizontally.
        Player winner = checkWinnerDir(row, 0, 0, 1);

        if (winner == Player.None) {
            // Look vertically.
            winner = checkWinnerDir(0, col, 1, 0);
        }

        return winner;
    }

    public Player winner() {
        int row = 0, col = 0;
        Player winner = Player.None;

        for (; checkBounds(row, col); row++) {
            if (winner == Player.None) {
                winner = checkWinnerFromPos(row, col);
            }

            col++;
        }

        // Check diagonals.
        if (winner == Player.None) {
            winner = checkWinnerDir(0, 0, 1, 1);

            if (winner == Player.None) {
                winner = checkWinnerDir(0, 2, 1, -1);
            }
        }

        if (winner == Player.X || winner == Player.O) {
            return winner;
        } else if (blanks().length == 0) {
            return Player.Both;
        } else {
            return Player.None;
        }
    }

    public Position[] blanks() {
        ArrayList<Position> arr = new ArrayList<Position>();

        for (int row = 0; row < ROWS; row++) {
            for (int col = 0; col < COLS; col++) {
                if (grid[row][col] == Player.None) {
                    arr.add(new Position(row, col));
                }
            }
        }

        return arr.toArray(new Position[arr.size()]);
    }

    private int[][] getCorners() {
        // The style checker may cause aneurysms.
        int[][] corners = {
            {
                0, 0
            }
            ,
            {
                2, 2
            }
            ,
            {
                0, 2
            }
            ,
            {
                2, 0
            }
        };

        return corners;
    }

    private Position checkOppositeCorner(Player a, Player other) {
        int row, col;
        int[][] corners = getCorners();

        for (int[] corner : corners) {
            if (grid[corner[0]][corner[1]] == a) {
                // If 0, set 2, or vice versa.
                row = (corner[0] == 0) ? 2 : 0;
                col = (corner[1] == 0) ? 2 : 0;

                // If the opposite is other, return it.
                if (grid[row][col] == other) {
                    return new Position(row, col);
                }
            }
        }

        // If the opposite doesn't match, return null.
        return null;
    }

    private Position findOppositeCorner(Player other) {
        return checkOppositeCorner(other, Player.None);
    }

    private Position findFreeCorner() {
        int[][] corners = getCorners();

        for (int[] corner : corners) {
            if (grid[corner[0]][corner[1]] == Player.None) {
                return new Position(corner[0], corner[1]);
            }
        }

        return null;
    }

    private Position blockFork(Player other) {
        boolean ownOpp = checkOppositeCorner(other, other) != null;
        boolean ownCenter = grid[1][1] == other.other();
        if (ownOpp && ownCenter && blanks().length == 6) {
            // Play an edge if X owns two corners..
            return new Position(0, 1);
        } else {
            return tryFork(other);
        }
    }


    public Position suggest() {
        Position[] opts;
        Position opt;

        // First, try to win.
        opts = findPairs(this.turn);
        if (opts.length > 0) {
            return opts[0];
        }

        // Next, block the win of the other player.
        opts = findPairs(this.turn.other());
        if (opts.length > 0) {
            return opts[0];
        }

        // Try to create a fork for ourself.
        opt = tryFork(this.turn);
        if (opt != null) {
            return opt;
        }

        // Block the opponent's fork.
        opt = blockFork(this.turn.other());
        if (opt != null) {
            return opt;
        }

        // Take center.
        if (grid[1][1] == Player.None) {
            return new Position(1, 1);
        }

        // Take the corner opposite the opponent.
        opt = findOppositeCorner(this.turn.other());
        if (opt != null) {
            return opt;
        }

        // Take a free corner.
        opt = findFreeCorner();
        if (opt != null) {
            return opt;
        }

        // Finally, take the first free spot.
        opts = blanks();
        if (opts.length > 0) {
            return opts[0];
        } else {
            // This will only be the case if the game is over.
            return null;
        }
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("     1   2   3\n\n");

        for (int row = 0; row < ROWS; row++) {
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

            for (int col = 0; col < COLS; col++) {
                switch (grid[row][col]) {
                case X:
                    sb.append(" X");
                    break;
                case O:
                    sb.append(" O");
                    break;
                default:
                    if (col < COLS - 1) {
                        sb.append("  ");
                    }
                }

                if (col < COLS - 1) {
                    sb.append(" |");
                }
            }

            sb.append('\n');

            if (row < ROWS - 1) {
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
        return l.toLowerCase().charAt(0) - 97;
    }

    private static void checkToString() {
        Board b = new Board();

        b.move(b.position("a2"));
        b.move(b.position("a3"));
        b.move(b.position("b1"));
        b.move(b.position("b2"));
        b.grid[2][1] = Player.O;

        String testOutput = "     1   2   3\n\n a     | X | O\n    ---+---+-" +
            "--\n b   X | O |\n    ---+---+---\n c     | O |\n";

        if (!testOutput.equals(b.toString())) {
            throw new Error("toString test failed.");
        }
    }

    private static void checkConBlanks() {
        Board b = new Board();
        if (b.blanks().length != 9) {
            throw new Error("New Board not empty.");
        }

        b.move(new Position(0, 0));
        if (b.blanks().length != 8) {
            throw new Error("Move not removed from blanks.");
        }
    }

    private static void checkPosition() {
        Board b = new Board();
        Position pos = b.position("a3");
        if (pos.row() != 0 || pos.col() != 2) {
            throw new Error("position check failed.");
        }

        pos = b.position("g1");
        if (pos != null) {
            throw new Error("position check failed.");
        }
    }

    private static void checkMove() {
        Board b = new Board();
        Position pos = new Position(1, 1);
        b.move(pos);

        if (b.grid[1][1] != Player.X) {
            throw new Error("move check failed.");
        }
    }

    private static void checkWinner() {
        Board b = new Board();
        b.move(b.position("a2"));
        b.move(b.position("a3"));
        b.move(b.position("b1"));

        if (b.winner() != Player.None) {
            throw new Error("winner declared prematurely.");
        }

        b.move(b.position("b2"));
        b.move(b.position("c3"));
        b.move(b.position("c1"));

        if (b.winner() != Player.O) {
            throw new Error("winner check failed.");
        }
    }

    private static void checkSuggest() {
        Board b = new Board();

        while (b.winner() == Player.None) {
            b.move(b.suggest());
        }

        if (b.winner() != Player.Both) {
            throw new Error("AI check failed.");
        }
    }

    public static void main(String[] args) {
        // Run tests.
        checkConBlanks();
        checkToString();
        checkPosition();
        checkMove();
        checkWinner();
        checkSuggest();
    }
}
