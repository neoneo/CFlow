component ExistRule extends="Rule" {

	public void function setField(required string fieldName) {
		variables.fieldName = arguments.fieldName;
	}

	public boolean function test(required struct data) {
		return StructKeyExists(arguments.data, variables.fieldName);
	}

}