component MinimumDateTimeRule extends="DateTimeRule" {

	public boolean function test(required struct data) {

		var value = getValue(arguments.data);
		var compareValue = getParameterValue(arguments.data);

		return DateCompare(value, compareValue) >= 0;
	}

}