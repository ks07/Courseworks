package coms12400.cw5;

import coms12400.cw5.GridSpot.Marker;
import java.io.BufferedReader;
import java.util.List;
import java.util.Scanner;
import java.util.Set;

public class Minesweeper {
    private final int width, height;
    private final GridSpot[][] grid;
    
    public Minesweeper(int width, int height, int count) {
        if (width <= 0 || height <= 0 || count < 1) {
            throw new Error("Invalid grid parameters.");
        }
        
        this.width = width;
        this.height = height;
        grid = new GridSpot[width][height];
        
        Set<Position> mineSpots = Position.getRandPositions(width, height, count);
        
        for (int x = 0; x < width; x++) {
            for (int y = 0; y < height; y++) {
                Position p = new Position(x, y);
                
                if (mineSpots.contains(p)) {
                    grid[x][y] = new GridSpot(true);
                } else {
                    grid[x][y] = new GridSpot(false);
                }
            }
        }
        
        for (Position p : mineSpots) {
            for (Position pos : p.getAdjacent(width, height)) {
                getPos(pos).increment();
            }
        }
    }
    
    public void markPosition(Position pos, Marker mark) {
        getPos(pos).setMark(mark);
    }
    
    // Returns true if the player hasn't uncovered a mine (and thus lost).
    public boolean uncoverPosition(Position pos) {
        GridSpot spot = getPos(pos);
        
        if (spot.isMined()) {
            spot.setMark(Marker.UNCOVERED);
            return false;
        } else {
            uncoverPositionR(pos);
            return true;
        }
    }
    
    private void uncoverPositionR(Position pos) {
        GridSpot currSpot = getPos(pos);
        List<Position> adj = pos.getAdjacent(width, height);

        if (!currSpot.isMined() && currSpot.getMark() != Marker.UNCOVERED) {
            currSpot.setMark(Marker.UNCOVERED);
            for (Position next : adj) {
                uncoverPositionR(next);
            }
        }
    }
    
    public boolean hasWon() {
        for (int x = 0; x < width; x++) {
            for (int y = 0; y < height; y++) {
                GridSpot spot = grid[x][y];
                
                switch (spot.getMark()) {
                    case EMPTY:
                    case QUESTION:
                        // Grid not complete yet.
                        return false;
                    case FLAGGED:
                        // Incorrect spot marked (thus incomplete).
                        if (!spot.isMined()) {
                            return false;
                        }
                        break;
                }
            }
        }
        
        return true;
    }
    
    // Convenience method for accessing grid with a position object.
    private GridSpot getPos(Position pos) {
        return grid[pos.x][pos.y];
    }
    
    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        
        for (int y = height - 1; y >= 0; y--) {
            for (int x = width - 1; x >= 0; x--) {
                sb.append(grid[x][y].toString());
            }
            sb.append('\n');
        }
        
        return sb.toString();
    }
    
    public static void main(String[] args) {
        Minesweeper ms = new Minesweeper(10, 10, 20);
        
        System.out.print(ms.toString());
        System.out.println();
        Integer x, y;
        Scanner in = new Scanner(System.in);
        
        in.useDelimiter(",");
        while (true) {
            String l[] = in.nextLine().split(",");
            x = Integer.parseInt(l[0]);
            y = Integer.parseInt(l[1]);
            Position p = new Position(x, y);
            ms.uncoverPosition(p);
        System.out.print(ms.toString());
        System.out.println();
        }
    }
} 
