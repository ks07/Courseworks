package coms12400.cw5;

import java.awt.Dimension;
import java.awt.GridLayout;
import javax.swing.JFrame;

public class MinesweeperFrame extends JFrame {
    private final GridLayout minesGrid;
    
    public MinesweeperFrame() {
        setPreferredSize(new Dimension(400,300));
        minesGrid = new GridLayout(20,15);
    }
}
