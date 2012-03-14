component SatisfyRule implements="Rule" {

	public void function init(required string condition) {

		variables.evaluator = new cflow.util.Evaluator(arguments.condition);

	}

	public boolean function test(required struct data, required string fieldName) {
		return variables.evaluator.execute(arguments.data);
	}

}