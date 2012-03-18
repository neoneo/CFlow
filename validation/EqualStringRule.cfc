component EqualStringRule extends="StringRule" {

	public boolean function test(required struct data) {

		var value = getValue(arguments.data);
		var compareValue = getParameterValue(arguments.data);

		return compareValues(value, compareValue);
	}

}