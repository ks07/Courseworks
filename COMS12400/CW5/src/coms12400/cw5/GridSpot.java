package coms12400.cw5;

public class GridSpot {
    private int adjacentCount = 0;
    private final boolean mine;
    private Marker mark = Marker.EMPTY;
    
    public GridSpot(boolean mine) {
        this.mine = mine;
    }
    
    public boolean isMined() {
        return mine;
    }
    
    public void increment() {
        if (adjacentCount < 8) {
            adjacentCount++;
        } else {
            throw new Error("Increment called at max value.");
        }
    }
    
    public int getCount() {
        return adjacentCount;
    }
    
    public void setMark(Marker mark) {
        this.mark = mark;
    }
    
    public Marker getMark() {
        return mark;
    }
    
    @Override
    public String toString() {
        switch (this.mark) {
            case EMPTY:
                //return "#";
                if (this.isMined()) {
                    return "Y";
                } else {
                    return "#";
                }
            case FLAGGED:
                return "F";
            case QUESTION:
                return "?";
            case UNCOVERED:
                return Integer.toString(adjacentCount);
            default:
                return "_";
        }
    }
        
    public enum Marker {
        EMPTY, UNCOVERED, FLAGGED, QUESTION;
    }
}
