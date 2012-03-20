/**
 * EachRuleSet is a RuleSet that tests its rules against all elements in a given set.
 **/
component EachRuleSet extends="RuleSet" {

	public void function init(boolean aggregate = false) {
		variables.aggregate = arguments.aggregate;
	}

	public void function setField(required string fieldName) {
		variables.fieldName = arguments.fieldName;
	}

	public array function validate(required struct data) {

		var messages = [];
		var set = toArray(arguments.data[variables.fieldName]);

		// create a copy of the data that we can modify
		var transport = StructCopy(arguments.data);
		for (var element in set) {
			// replace the field with the element
			transport[variables.fieldName] = element;
			// call the super method, so the element is tested against the rules
			var result = super.validate(transport);
			if (variables.aggregate) {
				// only include distinct messages
				for (var message in result) {
					if (!ArrayContains(messages, message)) {
						ArrayAppend(messages, message);
					}
				}
			} else {
				// put the results on the messages array unmodified
				// so the result is an array within an array
				ArrayAppend(messages, result);
			}
		}

		return messages;
	}

	private array function toArray(required any value) {

		var result = JavaCast("null", 0);
		if (IsArray(arguments.value)) {
			result = arguments.value;
		} else {
			result = ListToArray(arguments.value);
		}

		return result;
	}

}