component NonEmptyRule extends="Rule" {

	public boolean function test(required struct data) {
		return Len(arguments.data[getField()]) > 0;
	}

}