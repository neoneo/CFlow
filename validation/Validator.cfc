component Validator {

	variables.ruleSets = {};
	variables.names = [];

	public void function addRuleSet(required RuleSet ruleSet, required string name, array mustPass = []) {
		variables.ruleSets[arguments.name] = {
			instance = arguments.ruleSet,
			mustPass = arguments.mustPass
		};
		ArrayAppend(variables.names, arguments.name);
	}

	public struct function validate(required struct data) {

		var messages = {};

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
				messages[name] = info.instance.validate(arguments.data);
			}
		}

		return messages;
	}

}