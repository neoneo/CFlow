component NonEmptyRule implements="Rule" {

	public boolean function test(required struct data, required string fieldName) {
		return Len(arguments.data[arguments.fieldName]) > 0;
	}

}