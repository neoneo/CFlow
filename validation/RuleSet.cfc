component RuleSet {

	variables.rules = [];

	/**
	 * Adds a Rule to the RuleSet.
	 **/
	public void function addRule(required Rule rule, string message = "", string mask = "") {

		ArrayAppend(variables.rules, {
			instance = arguments.rule,
			message = arguments.message,
			silent = Len(arguments.message) == 0,
			mask = arguments.mask
		});

	}

	/**
	 * Adds the given rule set to the last rule of this rule set.
	 * The rule set being added is only evaluated when this last rule is passed.
	 **/
	public void function addRuleSet(required RuleSet ruleSet) {

		if (ArrayIsEmpty(variables.rules)) {
			Throw(type = "cflow.validation", message = "At least one rule must exist before a ruleset can be added");
		}
		// put the rule set on the last array item
		variables.rules[ArrayLen(variables.rules)].set = arguments.ruleSet;

	}

	public array function validate(required struct data) {

		var messages = []; // collection of error messages

		for (var rule in variables.rules) {
			var result = testRule(rule.instance, arguments.data);
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
					var message = rule.message;
					if (message contains "%value%") {
						message = Replace(message, "%value%", rule.instance.formatParameterValue(arguments.data, rule.mask));
					}
					ArrayAppend(messages, message);
				}
			}
		}

		return messages;
	}

	private boolean function testRule(required Rule rule, required struct data) {
		 return rule.test(arguments.data);
	}

}