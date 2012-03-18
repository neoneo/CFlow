component Rule {

	variables.value = "";
	variables.fieldName = "";
	variables.useValue = true; // whether to return the value when getValue() is called

	public boolean function test(required struct data) {
		Throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	public void function setField(required string fieldName) {
		variables.fieldName = arguments.fieldName;
		variables.useValue = false;
	}

	public void function setValue(required any value) {
		variables.value = arguments.value;
		variables.useValue = true;
	}

	private string function getField() {
		return variables.fieldName;
	}

	private any function getValue(required struct data) {

		var value = "";
		if (variables.useValue) {
			value = variables.value;
		} else {
			value = arguments.data[variables.fieldName];
		}

		return value;
	}

	// this method is included for working with sets
	private array function toArray(required any value) {

		var result = JavaCast("null", 0);
		if (IsArray(arguments.value)) {
			result = arguments.value;
		} else {
			result = ListToArray(arguments.value);
		}

		return result;
	}

}