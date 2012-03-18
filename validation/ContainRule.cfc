component ContainRule extends="StringRule" {

	public boolean function test(required struct data) {

		var value = getValue(arguments.data);
		var compareValue = getParameterValue(arguments.data);
		var result = false;

		if (getCaseSensitive()) {
			result = Find(compareValue, value) > 0;
		} else {
			result = value contains compareValue;
		}

		return result;
	}

}