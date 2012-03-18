component MinimumNumericRule extends="NumericRule" {

	public boolean function test(required struct data) {

		var value = getValue(arguments.data);
		var compareValue = getParameterValue(arguments.data);

		return value >= compareValue;
	}

}