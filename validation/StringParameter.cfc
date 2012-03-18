component NumericParameter extends="Parameter" {

	public string function getValue(required struct data) {
		return ToString(super.getValue(arguments.data));
	}

}