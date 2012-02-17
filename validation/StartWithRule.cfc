component StartWithRule extends="StringCompareRule" {

	public boolean function test(required struct data, required string fieldName) {

		var compareValue = getParameterValue(arguments.data);
		var value = Left(arguments.data[arguments.fieldName], Len(compareValue));

		return compareValues(value, parameterValue);
	}

}