component MinimumLengthRule extends="NumericRule" {

	public boolean function test(required struct data) {
		return Len(getValue(arguments.data)) >= getParameterValue(arguments.data);
	}

}