component DateTimeParameterRule implements="Rule" {

	public void function init(required string value, boolean evaluate = false) {

		variables.parameterStrategy = new DateTimeParameterStrategy();
		variables.parameterStrategy.setValue(arguments.value, arguments.evaluate);

	}

	public boolean function test(required struct data, required string fieldName) {
		throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	private date function getParameterValue(required struct data) {
		return variables.parameterStrategy.getValue(arguments.data);
	}

}