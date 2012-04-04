/*
   Copyright 2012 Neo Neo

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

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

	public EachRuleSet function createEachRuleSet(boolean aggregate = false) {
		return new EachRuleSet(aggregate);
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

	public EqualStringRule function createEqualStringRule(required string value, boolean caseSensitive = false) {
		return new EqualStringRule(arguments.value, arguments.caseSensitive);
	}

	public ContainRule function createContainRule(required string value, boolean caseSensitive = false) {
		return new ContainRule(arguments.value, arguments.caseSensitive);
	}

	public EndWithRule function createEndWithRule(required string value, boolean caseSensitive = false) {
		return new EndWithRule(arguments.value, arguments.caseSensitive);
	}

	public StartWithRule function createStartWithRule(required string value, boolean caseSensitive = false) {
		return new StartWithRule(arguments.value, arguments.caseSensitive);
	}

	public MatchRule function createMatchRule(required string pattern) {
		return new MatchRule(arguments.pattern);
	}

	public MinimumLengthRule function createMinimumLengthRule(required string value) {
		return new MinimumLengthRule(arguments.value);
	}

	public MaximumLengthRule function createMaximumLengthRule(required string value) {
		return new MaximumLengthRule(arguments.value);
	}

	// NUMERIC RULES ------------------------------------------------------------------------------

	public EqualNumericRule function createEqualNumericRule(required string value) {
		return new EqualNumericRule(arguments.value);
	}

	public MinimumNumericRule function createMinimumNumericRule(required string value) {
		return new MinimumNumericRule(arguments.value);
	}

	public MaximumNumericRule function createMaximumNumericRule(required string value) {
		return new MaximumNumericRule(arguments.value);
	}

	// DATE/TIME RULES ----------------------------------------------------------------------------

	public EqualDateTimeRule function createEqualDateTimeRule(required string value) {
		return new EqualDateTimeRule(arguments.value);
	}

	public MinimumDateTimeRule function createMinimumDateTimeRule(required string value) {
		return new MinimumDateTimeRule(arguments.value);
	}

	public MaximumDateTimeRule function createMaximumDateTimeRule(required string value) {
		return new MaximumDateTimeRule(arguments.value);
	}

	// SET RULES ----------------------------------------------------------------------------------

	public ElementRule function createElementRule(required string value, boolean caseSensitive = false) {
		return new ElementRule(arguments.value, arguments.caseSensitive);
	}

	public EqualSetRule function createEqualSetRule(required string value, boolean caseSensitive = false) {
		return new EqualSetRule(arguments.value, arguments.caseSensitive);
	}

	public IntersectionRule function createIntersectionRule(required string value, boolean caseSensitive = false) {
		return new IntersectionRule(arguments.value, arguments.caseSensitive);
	}

	public SubsetRule function createSubsetRule(required string value, boolean caseSensitive = false) {
		return new SubsetRule(arguments.value, arguments.caseSensitive);
	}

	public SupersetRule function createSupersetRule(required string value, boolean caseSensitive = false) {
		return new SupersetRule(arguments.value, arguments.caseSensitive);
	}

	public ValidSetRule function createValidSetRule(required string type) {
		return new ValidSetRule(arguments.type);
	}

	public MinimumCountRule function createMinimumCountRule(required string value) {
		return new MinimumCountRule(arguments.value);
	}

	public MaximumCountRule function createMaximumCountRule(required string value) {
		return new MaximumCountRule(arguments.value);
	}

	public DistinctRule function createDistinctRule(boolean caseSensitive = false) {
		return new DistinctRule(arguments.caseSensitive);
	}

}