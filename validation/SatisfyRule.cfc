component SatisfyRule implements="Rule" {

	public void function init(required string condition) {

		variables.evaluator = new Evaluator(arguments.condition);

	}

	public boolean function test(required struct data) {
		return variables.evaluator.execute(arguments.data);
	}

}