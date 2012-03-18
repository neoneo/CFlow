component StringRule extends="Rule" {

	public void function init(required string value, boolean evaluate = false, boolean caseSensitive = false) {

		variables.parameter = new StringParameter();
		variables.parameter.setValue(arguments.value, arguments.evaluate);
		variables.caseSensitive = arguments.caseSensitive;

	}

	public string function formatParameterValue(required struct data, required string mask) {
		return getParameterValue(arguments.data);
	}

	private string function getParameterValue(required struct data) {
		return variables.parameter.getValue(arguments.data);
	}

	private boolean function compareValues(required string value1, required string value2) {

		var result = false;

		if (variables.caseSensitive) {
			result = Compare(arguments.value1, arguments.value2) == 0;
		} else {
			result = CompareNoCase(arguments.value1, arguments.value2) == 0;
		}

		return result;
	}

	private boolean function getCaseSensitive() {
		return variables.caseSensitive;
	}

}