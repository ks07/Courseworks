class Grade {
    private int rawMark;

    public static void main(String[] args) {
	try {
	    Grade grade = new Grade(args[0]);

	    System.out.println(grade.getGradeDesc());
	} catch (IllegalArgumentException iae) {
	    System.err.println("Error: " + iae.getMessage());
	    System.exit(1);
	}
    }

    public Grade(String mark) throws IllegalArgumentException {
	try {
	    rawMark = Integer.parseInt(mark);
	} catch (NumberFormatException nfe) {
	    throw new IllegalArgumentException("The mark given is not a number!", nfe);
	}

	if (rawMark < 0 || rawMark > 100) {
	    throw new IllegalArgumentException("Percentage mark is outside of the acceptable range!");
	}
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