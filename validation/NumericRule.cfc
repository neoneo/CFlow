component NumericRule extends="Rule" {

	public void function init(required string value, boolean evaluate = false) {
		variables.parameter = new NumericParameter();
		variables.parameter.setValue(arguments.value, arguments.evaluate);
	}

	public string function formatParameterValue(required struct data, required string mask) {

		var result = "";
		var value = getParameterValue(arguments.data);

		if (Len(arguments.mask) == 0) {
			result = LSNumberFormat(value);
		} else {
			result = LSNumberFormat(value, arguments.mask);
		}

		return result;
	}

	private numeric function getParameterValue(required struct data) {
		return variables.parameter.getValue(arguments.data);
	}

}