component DateTimeRule implements="Rule" {

	public void function init(required string value, boolean evaluate = false) {

		variables.parameter = new DateTimeParameter();
		variables.parameter.setValue(arguments.value, arguments.evaluate);

	}

	public boolean function test(required struct data, required string fieldName) {
		throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	private date function getParameterValue(required struct data) {
		return variables.parameter.getValue(arguments.data);
	}

}