component Result {

	variables.messages = {};

	public void function addMessages(required string fieldName, required array messages) {

		if (!ArrayIsEmpty(arguments.messages)) {
			// there can be multiple calls using the same field name
			if (!StructKeyExists(variables.messages, arguments.fieldName)) {
				variables.messages[arguments.fieldName] = arguments.messages;
			} else {
				// append the messages on the existing array
				for (var message in arguments.messages) {
					ArrayAppend(variables.messages[arguments.fieldName], message);
				}
			}
		}

	}

	public boolean function isPassed(string fieldName) {

		var passed = true;
		if (!StructKeyExists(arguments, "fieldName")) {
			passed = StructIsEmpty(variables.messages);
		} else {
			passed = StructKeyExists(variables.messages, arguments.fieldName);
		}

		return passed;
	}

	public array function getFieldNames() {
		return StructKeyArray(variables.messages);
	}

	public array function getMessages(required string fieldName) {

		var messages = JavaCast("null", 0);
		if (StructKeyExists(variables.messages, arguments.fieldName)) {
			messages = variables.messages[arguments.fieldName];
		} else {
			messages = [];
		}

		return messages;
	}

}