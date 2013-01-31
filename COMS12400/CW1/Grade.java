class Grade {
    private int rawMark = 0;

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

    public Grade(String[] marks) throws IllegalArgumentException {
	int i, parsedMark;

	// Sum all the marks given.
	for (i = 0; i < marks.length; i++) {
	    try {
		parsedMark = Integer.parseInt(marks[i]);

		if (parsedMark < 0 || parsedMark > 100) {
		    throw new IllegalArgumentException("The percentage mark '" + marks[i] + "' is outside of the acceptable range!");
		} else {
		    rawMark += parsedMark;
		}

	    } catch (NumberFormatException nfe) {
		throw new IllegalArgumentException("The mark '" + marks[i] + "' is not a number!", nfe);
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