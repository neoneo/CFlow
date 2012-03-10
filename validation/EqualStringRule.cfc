component EqualStringRule extends="StringRule" {

	public boolean function test(required struct data, required string fieldName) {

		var value = arguments.data[arguments.fieldName];
		var compareValue = getParameterValue(arguments.data);

		return compareValues(value, compareValue);
	}

}