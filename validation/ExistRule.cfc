component ExistRule extends="Rule" {

	public boolean function test(required struct data) {
		return StructKeyExists(arguments.data, getField());
	}

}