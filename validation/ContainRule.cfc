component ContainRule extends="StringCompareRule" {

	public boolean function test(required struct data, required string fieldName) {

		var value = arguments.data[arguments.fieldName];
		var compareValue = getParameterValue(arguments.data);
		var result = false;

		if (getMatchCase()) {
			result = Find(compareValue, value) > 0;
		} else {
			result = value contains compareValue;
		}

		return result;
	}

}