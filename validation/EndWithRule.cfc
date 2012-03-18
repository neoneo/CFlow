component EndWithRule extends="StringRule" {

	public boolean function test(required struct data) {

		var compareValue = getParameterValue(arguments.data);
		var value = Right(getValue(arguments.data), Len(compareValue));

		return compareValues(value, compareValue);
	}

}