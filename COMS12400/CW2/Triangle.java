public class Triangle {
    private final int A, B, C;

    public static void main(String[] args) {
        try {
            Triangle tri = new Triangle(args);

            System.out.println(tri.getType());
        } catch (IllegalArgumentException iae) {
            System.err.println("Error: " + iae.getMessage());
        }
    }

    //    public static void doTests() {
    //        Triangle test;
    //
    //        test = new Triangle(0, 0, 0);
    //    }
    //
    //    public static boolean check(String args[], String expect) {
    //        Triangle test;
    //
    //        test = new Triangle(0, 0, 0);
    //    }

    public Triangle(String[] args) throws IllegalArgumentException {
        int lengths[] = parseSides(args);

        // C should hold the largest side.
        if (lengths[2] >= lengths[1] && lengths[2] >= lengths[0]) {
            C = lengths[2];
            B = lengths[1];
            A = lengths[0];
        } else if (lengths[1] >= lengths[0]) {
            sides[2] = lengths[1];
            sides[1] = lengths[2];
            sides[0] = lengths[0];
        } else {
            sides[2] = lengths[0];
            sides[1] = lengths[1];
            sides[0] = lengths[2];
        }
    }

    private static int[] parseSides(String[] sides) throws
    IllegalArgumentException {
        int[] ret = new int[3];

        if (sides.length == 3) {
            try {
                ret[0] = Integer.parseInt(sides[0]);
                ret[1] = Integer.parseInt(sides[1]);
                ret[2] = Integer.parseInt(sides[2]);
            } catch (NumberFormatException nfe) {
                throw new IllegalArgumentException("Side lengths not integers.",
                                                   nfe);
            }

            if (!isTriangle(ret[0], ret[1], ret[2])) {
                throw new IllegalArgumentException("Not a triangle.");
            }
        } else {
            throw new IllegalArgumentException("Not given three sides.");
        }

        return ret;
    }

    private static boolean isTriangle(int A, int B, int C) {
        return A + B > C && A + C > B && B + C > A;
    }

    public String getType() {
        if (isRightAngled()) {
            return "Right-Angled";
        } else if (sides[0] == sides[1] && sides[0] == sides[2]) {
            // All sides are equal.
            return "Equilateral";
        } else if (sides[0] == sides[1] || sides[0] == sides[2]
                   || sides[1] == sides[2]) {
            // Two are equal.
            return "Isosceles";
        } else {
            return "Scalene";
        }
    }

    public boolean isRightAngled() {
        //TODO: overflow
        return (sides[0] * sides[0] + sides[1] * sides[1] - sides[2] * sides[2])
        == 0;
    }
}
