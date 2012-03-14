component Context {

	variables.validators = {};

	public Validator function getValidator(required string name) {
		return variables.validators[arguments.name];
	}

	// FACTORY METHODS ============================================================================

	public Validator function createValidator(required string name) {

		variables.validators[arguments.name] = new Validator();

		return getValidator(arguments.name);
	}

	public RuleSet function createRuleSet() {
		return new RuleSet();
	}

	// GENERAL RULES ------------------------------------------------------------------------------

	public ExistRule function createExistRule() {
		return new ExistRule();
	}

	public NonEmptyRule function createNonEmptyRule() {
		return new NonEmptyRule();
	}

	public ValidRule function createValidRule(required string type) {
		return new ValidRule(arguments.type);
	}

	public SatisfyRule function createSatisfyRule(required string condition) {
		return new SatisfyRule(arguments.condition);
	}

	public NegateRule function createNegateRule(required Rule rule) {
		return new NegateRule(arguments.rule);
	}

	// STRING RULES -------------------------------------------------------------------------------

	public EqualStringRule function createEqualStringRule(required string value, boolean evaluate = false, boolean matchCase = false) {
		return new EqualStringRule(arguments.value, arguments.evaluate, arguments.matchCase);
	}

	public ContainRule function createContainRule(required string value, boolean evaluate = false, boolean matchCase = false) {
		return new ContainRule(arguments.value, arguments.evaluate, arguments.matchCase);
	}

	public EndWithRule function createEndWithRule(required string value, boolean evaluate = false, boolean matchCase = false) {
		return new EndWithRule(arguments.value, arguments.evaluate, arguments.matchCase);
	}

	public StartWithRule function createStartWithRule(required string value, boolean evaluate = false, boolean matchCase = false) {
		return new StartWithRule(arguments.value, arguments.evaluate, arguments.matchCase);
	}

	public MatchRule function createMatchRule(required string pattern) {
		return new MatchRule(arguments.pattern);
	}

	public MinimumLengthRule function createMinimumLengthRule(required string value, boolean evaluate = false) {
		return new MinimumLengthRule(arguments.value, arguments.evaluate);
	}

	public MaximumLengthRule function createMaximumLengthRule(required string value, boolean evaluate = false) {
		return new MaximumLengthRule(arguments.value, arguments.evaluate);
	}

	// NUMERIC RULES ------------------------------------------------------------------------------

	public EqualNumericRule function createEqualNumericRule(required string value, boolean evaluate = false) {
		return new EqualNumericRule(arguments.value, arguments.evaluate);
	}

	public MinimumNumericRule function createMinimumNumericRule(required string value, boolean evaluate = false) {
		return new MinimumNumericRule(arguments.value, arguments.evaluate);
	}

	public MaximumNumericRule function createMaximumNumericRule(required string value, boolean evaluate = false) {
		return new MaximumNumericRule(arguments.value, arguments.evaluate);
	}

	// DATE/TIME RULES ----------------------------------------------------------------------------

	public EqualDateTimeRule function createEqualDateTimeRule(required string value, boolean evaluate = false) {
		return new EqualDateTimeRule(arguments.value, arguments.evaluate);
	}

	public MinimumDateTimeRule function createMinimumDateTimeRule(required string value, boolean evaluate = false) {
		return new MinimumDateTimeRule(arguments.value, arguments.evaluate);
	}

	public MaximumDateTimeRule function createMaximumDateTimeRule(required string value, boolean evaluate = false) {
		return new MaximumDateTimeRule(arguments.value, arguments.evaluate);
	}

	// SET RULES ----------------------------------------------------------------------------------

	public ElementRule function createElementRule(required string value, boolean evaluate = false, boolean matchCase = false) {
		return new ElementRule(arguments.value, arguments.evaluate, arguments.matchCase);
	}

	public EqualSetRule function createEqualSetRule(required string value, boolean evaluate = false, boolean matchCase = false) {
		return new EqualSetRule(arguments.value, arguments.evaluate, arguments.matchCase);
	}

	public IntersectionRule function createIntersectionRule(required string value, boolean evaluate = false, boolean matchCase = false) {
		return new IntersectionRule(arguments.value, arguments.evaluate, arguments.matchCase);
	}

	public SubsetRule function createSubsetRule(required string value, boolean evaluate = false, boolean matchCase = false) {
		return new SubsetRule(arguments.value, arguments.evaluate, arguments.matchCase);
	}

	public SupersetRule function createSupersetRule(required string value, boolean evaluate = false, boolean matchCase = false) {
		return new SupersetRule(arguments.value, arguments.evaluate, arguments.matchCase);
	}

	public MinimumCountRule function createMinimumCountRule(required string value, boolean evaluate = false) {
		return new MinimumCountRule(arguments.value, arguments.evaluate);
	}

	public MaximumCountRule function createMaximumCountRule(required string value, boolean evaluate = false) {
		return new MaximumCountRule(arguments.value, arguments.evaluate);
	}

}