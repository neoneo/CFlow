component MaximumNumericRule extends="NumericParameterRule" {

	public boolean function test(required struct data, required string fieldName) {

		var value = arguments.data[arguments.fieldName];
		var compareValue = getParameterValue(arguments.data);

		return value <= compareValue;
	}

}