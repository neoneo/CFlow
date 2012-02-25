component MaximumLengthRule extends="NumericRule" {

	public boolean function test(required struct data, required string fieldName) {
		return Len(arguments.data[arguments.fieldName]) <= getParameterValue();
	}

}