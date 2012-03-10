component EvaluateTask extends="ComplexTask" {

	public void function init(required string condition) {

		variables.evaluator = new cflow.util.Evaluator(arguments.condition);

	}

	public boolean function run(required Event event) {

		if (variables.evaluator.execute(arguments.event)) {
			runSubtasks(arguments.event);
		}

		return true;
	}

}