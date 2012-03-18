component MinimumCountRule extends="NumericRule" {

	public boolean function test(required struct data) {
		return ArrayLen(toArray(getValue(arguments.data))) >= getParameterValue(arguments.data);
	}

}