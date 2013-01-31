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
	int i, creditPointSplit, avgDiv = marks.length;
	double parsedMark, parsedUnit = 1;
	boolean creditPoints = false;

	// Sum all the marks given.
	for (i = 0; i < marks.length; i++) {
	    if (getDecimalPlaces(marks[i]) > 1) {
		throw new IllegalArgumentException("The mark '" + marks[i] + "' contains too many decimal places.");
	    } else {
		creditPointSplit = marks[i].indexOf(':');
		if (creditPointSplit != -1) {
		    if (i > 0 && creditPoints == false) {
			// The previous argument(s) did not use credit points, but this new argument does.
			throw new IllegalArgumentException("Not all marks are provided with credit points!");
		    } else if (i == 0) {
			avgDiv = 0;
			creditPoints = true;
		    }
		} else if (i > 0 && creditPoints) {
		    // The previous argument(s) used credit points, but this new argument does not.
		    throw new IllegalArgumentException("Not all marks are provided with credit points!");
		}
		    

		try {
		    if (creditPoints) {
			parsedMark = Double.parseDouble(marks[i].substring(creditPointSplit + 1));
			parsedUnit = Double.parseDouble(marks[i].substring(0, creditPointSplit));

			avgDiv += parsedUnit;
		    } else {
			parsedMark = Double.parseDouble(marks[i]);
		    }

		    if (parsedMark < 0 || parsedMark > 100) {
			throw new IllegalArgumentException("The mark '" + marks[i] + "' is outside of the acceptable range!");
		    } else {
			if (creditPoints) {
			    parsedMark = parsedMark * parsedUnit;
			}

			rawMark += parsedMark;
		    }

		} catch (NumberFormatException nfe) {
		    throw new IllegalArgumentException("The mark '" + marks[i] + "' is not a number!", nfe);
		}
	    }
	}

	// Calculate the average mark.
	rawMark = rawMark / avgDiv;
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