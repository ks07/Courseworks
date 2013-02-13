// A Position object represents one particular position on the board, using row
// and column numbers (rows are 0, 1, 2 from top to bottom, and columns are 0,
// 1, 2 from left to right).  A position object can't be changed after it is
// created.

class Position
{
    private int row, col;

    // Create a Position with the given coordinates.

    Position(int r, int c)
    {
        if (r < 0 || r > 2) throw new Error("Coordinate out of range");
        if (c < 0 || c > 2) throw new Error("Coordinate out of range");
        row = r;
        col = c;
    }

    // Return the row numer.

    int row()
    {
        return row;
    }

    // Return the column numer.

    int col()
    {
        return col;
    }
}
