component RuleSet {

	variables.rules = [];

	public void function addRule(required Rule rule, required string message, boolean silent = false) {

		ArrayAppend(variables.rules, {
			instance = arguments.rule,
			message = arguments.message,
			silent = arguments.silent
		});

	}

	public void function addRuleSet(required RuleSet ruleSet) {

		if (ArrayIsEmpty(variables.rules)) {
			throw(type = "cflow.validation", message = "At least one rule must exist before a ruleset can be added");
		}
		// put the rule set on the last array item
		variables.rules[ArrayLen(variables.rules)].set = arguments.ruleSet;

	}

	public array function validate(required struct data) {

		var messages = []; // collection of error messages

		for (var rule in variables.rules) {
			var result = rule.instance.test(arguments.data);
			if (result) {
				// the rule is passed; if there is a rule set, validate its rules
				if (StructKeyExists(rule, "set")) {
					// concatenate any resulting messages on the current messages array
					var setMessages = rule.set.validate(arguments.data);
					for (var message in setMessages) {
						ArrayAppend(messages, message);
					}
				}
			} else {
				// not passed
				if (!rule.silent) {
					ArrayAppend(messages, rule.message);
				}
			}

		}

		return messages;
	}

}