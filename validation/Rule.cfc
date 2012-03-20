component Rule {

	variables.fieldName = "";

	public boolean function test(required struct data) {
		Throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	public void function setField(required string fieldName) {
		variables.fieldName = arguments.fieldName;
	}

	private string function getField() {
		return variables.fieldName;
	}

	private any function getValue(required struct data) {
		return arguments.data[variables.fieldName];
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