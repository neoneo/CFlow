component MatchRule extends="Rule" {

	public void function init(required string pattern) {
		variables.pattern = arguments.pattern;
	}

	public boolean function test(required struct data) {
		return IsValid("regex", arguments.data[getField()], variables.pattern);
	}

}