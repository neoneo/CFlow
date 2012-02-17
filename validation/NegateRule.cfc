component NegateRule implements="Rule" {

	public void function init(required Rule rule) {
		variables.rule = arguments.rule;
	}

	public boolean function test(required struct data, required string fieldName) {
		return !variables.rule.test(arguments.data, arguments.fieldName);
	}

}