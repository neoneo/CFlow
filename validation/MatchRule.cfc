component MatchRule implements="Rule" {

	public void function init(required string pattern) {
		variables.pattern = arguments.pattern;
	}

	public boolean function test(required struct data, required string fieldName) {
		return IsValid("regex", arguments.data[arguments.fieldName], variables.pattern);
	}

}