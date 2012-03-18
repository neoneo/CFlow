component NegateRule extends="Rule" {

	public void function init(required Rule rule) {
		variables.rule = arguments.rule;
	}

	public boolean function test(required struct data) {
		return !variables.rule.test(arguments.data);
	}

}