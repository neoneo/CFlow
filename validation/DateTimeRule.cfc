component DateTimeRule extends="Rule" {

	public void function init(required string value, boolean evaluate = false) {

		variables.parameter = new DateTimeParameter();
		variables.parameter.setValue(arguments.value, arguments.evaluate);

	}

	public string function formatParameterValue(required struct data, required string mask) {

		var result = "";
		var value = getParameterValue(arguments.data);

		if (Len(arguments.mask) == 0) {
			result = LSDateFormat(value);
		} else {
			result = LSDateFormat(value, arguments.mask);
		}

		return result;
	}

	private date function getParameterValue(required struct data) {
		return variables.parameter.getValue(arguments.data);
	}

}