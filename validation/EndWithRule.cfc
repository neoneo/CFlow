component EndWithRule extends="StringRule" {

	public boolean function test(required struct data, required string fieldName) {

		var compareValue = getParameterValue(arguments.data);
		var value = Right(arguments.data[arguments.fieldName], Len(compareValue));

		return compareValues(value, parameterValue);
	}

}