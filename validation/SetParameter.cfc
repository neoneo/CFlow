component SetParameter extends="StringParameter" {

	public array function getValue(required struct data) {
		// interpret the value as a comma separated list
		return ListToArray(super.getValue(arguments.data));
	}

}