component EqualStringRule extends="StringCompareRule" {

	public boolean function test(required struct data, required string fieldName) {

		var value = arguments.data[arguments.fieldName];
		var parameterValue = getParameterValue(arguments.data);

		return compareValues(value, parameterValue);
	}

}