component NonEmptyRule extends="Rule" {

	public void function setField(required string fieldName) {
		variables.fieldName = arguments.fieldName;
	}

	public boolean function test(required struct data) {
		return Len(arguments.data[variables.fieldName]) > 0;
	}

}