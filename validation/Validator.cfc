component Validator {

	variables.ruleSets = {};
	variables.names = [];

	public void function addRuleSet(required RuleSet ruleSet, required string name, array passedSets = []) {
		variables.ruleSets[arguments.name] = {
			instance = arguments.ruleSet,
			passedSets = arguments.passedSets
		};
		ArrayAppend(variables.names, arguments.name);
	}

	public struct function validate(required struct data) {

		var messages = {};

		for (var name in variables.names) {
			var info = variables.ruleSets[name];
			// check if there are other rule sets that have to have passed successfully
			var perform = ArrayIsEmpty(info.passedSets);
			if (!perform) {
				perform = true;
				for (var name in info.passedSets) {
					// the name has to occur in the messages struct, and has to be an empty array
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