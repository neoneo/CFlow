component MinimumCountRule extends="NumericParameterRule" {

	public void function init(required string value, boolean evaluate = false, string delimiter = ",") {
		super.init(arguments.value, arguments.evaluate);
		variables.delimiter = arguments.delimiter;
	}

	public boolean function test(required struct data, required string fieldName) {
		return ListLen(arguments.data[arguments.fieldName], variables.delimiter) >= getParameterValue();
	}

}