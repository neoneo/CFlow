component StringRule implements="Rule" {

	public void function init(required string value, boolean evaluate = false, boolean matchCase = false) {

		variables.parameter = new StringParameter();
		variables.parameter.setValue(arguments.value, arguments.evaluate);
		variables.matchCase = arguments.matchCase;

	}

	public boolean function test(required struct data, required string fieldName) {
		throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	private string function getParameterValue(required struct data) {
		return variables.parameter.getValue(arguments.data);
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

}