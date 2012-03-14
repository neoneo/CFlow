component Validator {

	variables.ruleSets = {};
	variables.names = [];

	public void function addRuleSet(required RuleSet ruleSet, required string name, string fieldName = "", array mustPass = []) {

		var fieldName = arguments.fieldName;
		if (Len(fieldName) == 0) {
			fieldName = arguments.name;
		}

		variables.ruleSets[arguments.name] = {
			instance = arguments.ruleSet,
			field = fieldName,
			mustPass = arguments.mustPass
		};
		ArrayAppend(variables.names, arguments.name);

	}

	public Result function validate(required struct data) {

		var result = new Result();

		for (var name in variables.names) {
			var info = variables.ruleSets[name];
			// check if there are other rule sets that must have been passed successfully
			var perform = ArrayIsEmpty(info.mustPass);
			if (!perform) {
				// rule sets in the mustPass array must have been passed (and therefore tested)
				perform = true;
				for (var name in info.mustPass) {
					// the name must occur in the messages struct, and must be an empty array
					// if the name is not in the messages struct, the rule set has not been tested
					// if the name is there, but the array is not empty, the rule set has failed tests
					if (!StructKeyExists(messages, name) || !ArrayIsEmpty(messages[name])) {
						perform = false;
						break;
					}
				}
			}

			if (perform) {
				var messages = info.instance.validate(arguments.data, info.field);
				result.addMessages(info.field, messages);
			}
		}

		return result;
	}

}