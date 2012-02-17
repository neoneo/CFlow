component StringCompareRule extends="StringParameterRule" {

	public void function init(required string value, boolean evaluate = false, boolean matchCase = false) {
		super.init(arguments.value, arguments.evaluate);
		variables.matchCase = arguments.matchCase;
	}

	private boolean function compareValues(required string value1, required string value2) {

		var result = false;

		if (variables.matchCase) {
			result = Compare(arguments.value1, arguments.value2) == 0;
		} else {
			result = CompareNoCase(arguments.value1, arguments.value2) == 0;
		}

		return result;
	}

	private boolean function getMatchCase() {
		return variables.matchCase;
	}

}