class Grade {
    private double rawMark = 0;

    public static void main(String[] args) {
	if (args.length == 0) {
	    System.err.println("Usage: java Grade.class <percentage mark> [percentage mark...]");
	} else {
	    try {
		Grade grade = new Grade(args);

		System.out.println(grade.getGradeDesc());
	    } catch (IllegalArgumentException iae) {
		System.err.println("Error: " + iae.getMessage());
		System.exit(1);
	    }
	}
    }

    // Gets the number of decimal places in a given string.
    private static int getDecimalPlaces(String dbl) {
	String[] split = dbl.split("\\.");

	if (split.length == 1) {
	    return 0;
	} else if (split.length == 2) {
	    return split[1].length();
	} else {
	    // Return -1 if there are multiple decimal points.
	    return -1;
	}
    }
	    

    public Grade(String[] marks) throws IllegalArgumentException {
	int i;
	double parsedMark;

	// Sum all the marks given.
	for (i = 0; i < marks.length; i++) {
	    if (getDecimalPlaces(marks[i]) > 1) {
		throw new IllegalArgumentException("The mark '" + marks[i] + "' contains too many decimal places.");
	    } else {
		try {
		    parsedMark = Double.parseDouble(marks[i]);

		    if (parsedMark < 0 || parsedMark > 100) {
			throw new IllegalArgumentException("The percentage mark '" + marks[i] + "' is outside of the acceptable range!");
		    } else {
			rawMark += parsedMark;
		    }

		} catch (NumberFormatException nfe) {
		    throw new IllegalArgumentException("The mark '" + marks[i] + "' is not a number!", nfe);
		}
	    }
	}

	// Calculate the average mark.
	rawMark = rawMark / marks.length;
    }

    public String getGradeDesc() {
	if (rawMark < 40) {
	    return "Fail";
	} else if (rawMark < 50) {
	    return "Third Class";
	} else if (rawMark < 60) {
	    return "Lower Second Class";
	} else if (rawMark < 70) {
	    return "Upper Second Class";
	} else if (rawMark < 80) {
	    return "First";
	} else if (rawMark < 90) {
	    return "Above and Beyond";
	} else if (rawMark < 100) {
	    return "Publishable";
	} else {
	    return "Perfect";
	}
    }
}