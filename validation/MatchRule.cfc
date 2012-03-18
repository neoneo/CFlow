component MatchRule extends="Rule" {

	public void function init(required string pattern) {
		variables.pattern = arguments.pattern;
	}

	public void function setField(required string fieldName) {
		variables.fieldName = arguments.fieldName;
	}

	public boolean function test(required struct data) {
		return IsValid("regex", arguments.data[variables.fieldName], variables.pattern);
	}

}