component SetParameter extends="Parameter" {

	variables.hasValue = false;

	public void function setValue(required any value, boolean evaluate = false) {

		if (IsArray(arguments.value)) {
			variables.value = arguments.value;
			variables.hasValue = true;
		} else {
			super.setValue(arguments.value, arguments.evaluate);
		}

	}

	public array function getValue(required struct data) {

		var value = JavaCast("null", 0);

		if (variables.hasValue) {
			value = variables.value;
		} else {
			value = super.getValue(arguments.data);
			if (!IsArray(value)) {
				// interpret the value as a comma separated list
				value = ListToArray(value);
			}
		}

		return value;
	}

}