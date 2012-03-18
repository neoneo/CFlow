component NumericParameter extends="Parameter" {

	public void function setValue(required string expression, boolean evaluate = false) {

		// ignore evaluate; only evaluate when the expression is not numeric
		super.setValue(arguments.expression, !IsNumeric(arguments.expression));

	}

	public numeric function getValue(required struct data) {
		return Val(super.getValue(arguments.data));
	}

}