/**
 * ApplyRuleSet is a RuleSet that tests its rules against all elements in a given set.
 **/
component ApplyRuleSet extends="RuleSet" {

	public void function setField(required string fieldName) {
		variables.fieldName = arguments.fieldName;
	}

	public void function addRule(required Rule rule, string message = "", string mask = "") {

		arguments.rule.setField("field");
		super.addRule(arguments.rule, arguments.message, arguments.mask);

	}

	private boolean function testRule(required Rule rule, required struct data) {

		// the down side to using this template method is that the set is reconstructed for every rule
		var set = toArray(arguments.data[variables.fieldName]);
		var result = true;
		// the rule must apply to all elements in the set
		for (var element in set) {
			// use a struct to conform to the Rule interface
			if (!rule.test({field = element})) {
				result = false;
				break;
			}
		}

		return result;
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