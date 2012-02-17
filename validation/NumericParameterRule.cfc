component NumericParameterRule implements="Rule" {

	public void function init(required string value, boolean evaluate = false) {

		variables.parameterStrategy = new NumericParameterStrategy();
		variables.parameterStrategy.setValue(arguments.value, arguments.evaluate);

	}

	public boolean function test(required struct data, required string fieldName) {
		throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	private numeric function getParameterValue(required struct data) {
		return variables.parameterStrategy.getValue(arguments.data);
	}

}