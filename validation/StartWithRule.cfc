component StartWithRule extends="StringRule" {

	public boolean function test(required struct data) {

		var compareValue = getParameterValue(arguments.data);
		var value = Left(getValue(arguments.data), Len(compareValue));

		return compareValues(value, parameterValue);
	}

}