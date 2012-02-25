component MaximumDateTimeRule extends="DateTimeRule" {

	public boolean function test(required struct data, required string fieldName) {

		var value = arguments.data[arguments.fieldName];
		var compareValue = getParameterValue(arguments.data);

		return DateCompare(value, compareValue) <= 0;
	}

}