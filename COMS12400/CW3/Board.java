import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class Board {

    private static final int DIMENSIONS = 3;

    private final Pattern posRegex;
    private final Player[][] grid;

    private Player turn;
    private Player gameState = Player.None;

    public Board() {
	posRegex = Pattern.compile("([abc])([123])");
	grid = new Player[DIMENSIONS][DIMENSIONS];
	turn = Player.X;
    }

    public Position position(String s) {
	Matcher match = posRegex.matcher(s);

	if (match.matches()) {
	    int let = letterToIndex(match.group(1));
	    int num = Integer.parseInt(match.group(2));

	    return new Position(let, num);
	} else {
	    return null;
	}
    }

    private int letterToIndex(String l) {
	char val = l.toLowerCase().charAt(0);

	return val - 97;
    }

    public static int main(String[] args) {
	// Run tests.
	Board b = new Board();
	println(b.position("a0"));
	println(b.position("b2"));
	println(b.position("c1"));
    }

    public static void println(String s) {
	System.out.println(s);
    }