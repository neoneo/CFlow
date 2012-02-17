component ExistRule implements="Rule" {

	public boolean function test(required struct data, required string fieldName) {
		return StructKeyExists(arguments.data, arguments.fieldName);
	}

}