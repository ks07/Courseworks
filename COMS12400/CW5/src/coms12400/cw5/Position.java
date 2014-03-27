package coms12400.cw5;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Random;
import java.util.Set;

public class Position {
    public final int x;
    public final int y;
    
    public Position(int x, int y) {
        this.x = x;
        this.y = y;
    }
    
    public List<Position> getAdjacent(int maxX, int maxY) {
        ArrayList<Position> ret = new ArrayList<Position>(8);

        for (int tmpX = x - 1; tmpX <= x + 1; tmpX++) {
            for (int tmpY = y - 1; tmpY <= y + 1; tmpY++) {
                boolean allowX = tmpX >= 0 && tmpX < maxX;
                boolean allowY = tmpY >= 0 && tmpY < maxY;
                if (allowX && allowY && !(tmpX == tmpY && tmpY == y)) {
                    ret.add(new Position(tmpX, tmpY));
                }
            }
        }

        return ret;
    }

    // Auto-Generated
    @Override
    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        final Position other = (Position) obj;
        if (this.x != other.x) {
            return false;
        }
        if (this.y != other.y) {
            return false;
        }
        return true;
    }

    @Override
    public int hashCode() {
        int hash = 5;
        hash = 23 * hash + this.x;
        hash = 23 * hash + this.y;
        return hash;
    }
    
    public static Set<Position> getRandPositions(int maxX, int maxY, int count) throws IllegalArgumentException {
        if (maxX * maxY < count) {
            throw new IllegalArgumentException("Count greater than possible spaces.");
        }

        HashSet<Position> ret = new HashSet<Position>(count);
        Random rng = new Random();
        
        // Not very efficient, but gets the job done eventually.
        while (count > 0) {
            Position pos = new Position(rng.nextInt(maxX), rng.nextInt(maxY));
            if (ret.add(pos)) {
                // If the position was not taken already, we can decrease count.
                count--;
            }
        }
        
        return ret;
    }
}
