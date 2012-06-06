component Condition {

	variables.parts = [];
	variables.operator = "AND"; // AND or OR; the operator to apply to the next part (next method call)
	variables.negation = false; // whether to negate the next part

	public Condition function and(Condition condition) {

		variables.operator = "AND";
		if (StructKeyExists(arguments, "condition")) {
			add("condition", arguments.condition.getParts());
		}
		return this;
	}

	public Condition function or(Condition condition) {

		variables.operator = "OR";
		if (StructKeyExists(arguments, "condition")) {
			add("condition", arguments.condition.getParts());
		}
		return this;
	}

	public Condition function not(Condition condition) {

		variables.negation = !variables.negation;
		if (StructKeyExists(arguments, "condition")) {
			add("condition", arguments.condition.getParts());
		}
		return this;
	}

	public Condition function in(required any leftValue, required any rightValue) {
		add("in", arguments);
		return this;
	}

	public Condition function equals(required any leftValue, required any rightValue) {
		add("equals", arguments);
		return this;
	}

	public Condition function greater(required any leftValue, required any rightValue) {
		add("greater", arguments);
		return this;
	}

	public Condition function less(required any leftValue, required any rightValue) {
		add("less", arguments);
		return this;
	}

	public Condition function greaterEqual(required any leftValue, required any rightValue) {
		add("greaterEqual", arguments);
		return this;
	}

	public Condition function lessEqual(required any leftValue, required any rightValue) {
		add("lessEqual", arguments);
		return this;
	}

	public Condition function like(required any leftValue, required any rightValue, string escape) {
		add("like", arguments);
		return this;
	}

	public Condition function isNull(required any leftValue) {
		add("isNull", arguments);
		return this;
	}

	public Condition function between(required any leftValue, required any value1, required any value2) {
		add("between", arguments);
		return this;
	}

	public Condition function exists(required any leftValue, required SelectStatement statement) {
		add("exists", arguments);
		return this;
	}

	private void function add(required string type, required any data) {

		ArrayAppend(variables.parts, {
			operator = variables.operator,
			negation = variables.negation,
			type = arguments.type,
			data = arguments.data
		});
		// reset the operator and negation
		variables.operator = "AND";
		variables.negation = false;

	}

	public array function getParts() {
		return variables.parts;
	}

}