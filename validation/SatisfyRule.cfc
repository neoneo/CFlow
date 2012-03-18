component SatisfyRule extends="Rule" {

	public void function init(required string condition) {
		variables.evaluator = new cflow.util.Evaluator(arguments.condition);
	}

	public boolean function test(required struct data) {
		return variables.evaluator.execute(arguments.data);
	}

}