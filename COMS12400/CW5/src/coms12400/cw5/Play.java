package coms12400.cw5;

import javax.swing.SwingUtilities;

public class Play implements Runnable {

    @Override
    public void run() {
        Play program = new Play();
        SwingUtilities.invokeLater(program);
    }
    
    public static void main(String[] args) {
        Minesweeper ms = new Minesweeper(10, 10, 20);
        
        System.out.print(ms.toString());
        System.out.println();
        ms.uncoverPosition(new Position(0, 0));
        System.out.print(ms.toString());
        System.out.println();
        ms.uncoverPosition(new Position(9, 7));
        System.out.print(ms.toString());
        System.out.println();
        ms.uncoverPosition(new Position(8, 6));
        System.out.print(ms.toString());
        System.out.println();
        ms.uncoverPosition(new Position(3, 2));
        System.out.print(ms.toString());
        System.out.println();
        ms.uncoverPosition(new Position(4, 8));
        System.out.print(ms.toString());
        System.out.println();
        ms.uncoverPosition(new Position(9, 1));
        System.out.print(ms.toString());
        System.out.println();
        ms.uncoverPosition(new Position(9, 3));
        System.out.print(ms.toString());
    }
}
