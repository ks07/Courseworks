public class Triangle {
    private long A, B, C;

    public static void main(String[] args) {
	    
        try {
            Triangle tri = new Triangle();

	    if (args.length == 0) {
		// Run tests if no arguments are supplied.
		tri.doTests();
	    } else {
		tri.init(args);

		System.out.println(tri.getType());
	    }
        } catch (IllegalArgumentException iae) {
            System.err.println("Error: " + iae.getMessage());
	    System.exit(1);
        }
    }

    void doTests() {
        check("0 0 0", false, "Lengths must be at least 1.");
	check("3 4 5", true, "Right-Angled");
	check("10 10 10", true, "Equilateral");
	check("10 10 9", true, "Isosceles");
	check("7 8 9", true, "Scalene");
	check("a b c", false, "Side lengths not integers.");
	check("345", false, "Not given three sides.");
	check("1.2 3.4 5.6", false, "Side lengths not integers.");
	check("1 15 100", false, "Not a triangle.");
    }

    void check(String line, boolean ok, String expect) {
        String args[] = line.split(" ");

	try {
	    init(args);

	    if (!getType().equals(expect)) {
		throw new Error(line);
	    }
	} catch (IllegalArgumentException iae) {
	    if (ok || !iae.getMessage().equals(expect)) {
		throw new Error(line);
	    }	
	}
    }

    void init(String[] args) throws IllegalArgumentException {
        long lengths[] = parseSides(args);

        for (long len : lengths) {
            if (len > 2147483647) {
                throw new IllegalArgumentException("Side too long.");
            }
        }

        // C should hold the largest side.
        if (lengths[2] >= lengths[1] && lengths[2] >= lengths[0]) {
            C = lengths[2];
            B = lengths[1];
            A = lengths[0];
        } else if (lengths[1] >= lengths[0]) {
            C = lengths[1];
            B = lengths[2];
            A = lengths[0];
        } else {
            C = lengths[0];
            B = lengths[1];
            A = lengths[2];
        }
    }

    long[] parseSides(String[] sides) throws IllegalArgumentException {
        if (sides.length != 3) {
            throw new IllegalArgumentException("Not given three sides.");
        }

        long[] ret = new long[3];

        try {
            ret[0] = Long.parseLong(sides[0]);
            ret[1] = Long.parseLong(sides[1]);
            ret[2] = Long.parseLong(sides[2]);
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Side lengths not integers.");
        }

        if (ret[0] < 1 || ret[1] < 1 || ret[2] < 1) {
            throw new IllegalArgumentException("Lengths must be at least 1.");
        }

        if (!isTriangle(ret[0], ret[1], ret[2])) {
            throw new IllegalArgumentException("Not a triangle.");
        }

        return ret;
    }

    boolean isTriangle(long A, long B, long C) {
        return A + B > C && A + C > B && B + C > A;
    }

    String getType() {
        if (isRightAngled()) {
            return "Right-Angled";
        } else if (A == B && A == C) {
            // All sides are equal.
            return "Equilateral";
        } else if (A == B || A == C || B == C) {
            // Two are equal.
            return "Isosceles";
        } else {
            return "Scalene";
        }
    }

    boolean isRightAngled() {
        // Max input is small enough such that this will not overflow.
        return (A * A + B * B - C * C) == 0;
    }
}
