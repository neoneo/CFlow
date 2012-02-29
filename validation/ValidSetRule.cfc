/**
 * Checks if all elements in the set are valid.
 **/
component ValidSetRule extends="SetRule" {

	public void function init(required string type) {

		variables.type = arguments.type;
		variables.validRule = new ValidRule(arguments.type);

	}

	public boolean function test(required struct data, required string fieldName) {

		var result = true;

		var set = toArray(arguments.data[arguments.fieldName]);
		// create a fake data struct in order to get the ValidRule to work for us
		var transport = {};

		for (var element in set) {
			transport.field = element;
			// use the transport struct to conform to the Rule interface
			if (!variables.validRule.test(transport, "field")) {
				result = false;
				break;
			}
		}

		return result;
	}

}