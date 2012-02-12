component Validator {

	variables.ruleSets = {};
	variables.setNames = [];

	public void function addRuleSet(required RuleSet ruleSet, required string name) {
		variables.ruleSets[arguments.name] = arguments.ruleSet;
		ArrayAppend(variables.setNames, arguments.name);
	}

	public struct function validate(required struct data) {

		var messages = {};
		var result = JavaCast("null", 0);

		for (var setName in variables.setNames) {
			messages[setName] = variables.ruleSets[setName].validate(arguments.data);
		}

		return messages;
	}

}