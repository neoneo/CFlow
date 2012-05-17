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

component XmlReader {

	public void function init(required Context context) {
		variables.context = arguments.context;
	}

	public void function read(required string path) {

		var absolutePath = ExpandPath(arguments.path);
		var list = DirectoryList(absolutePath, true, "name", "*.xml");

		for (var name in list) {
			readFile(absolutePath & "/" & name);
		}

	}

	private void function readFile(required string path) {

		var content = FileRead(arguments.path);
		var xmlDocument = XmlParse(content, false);

		// the root element should be validator
		if (xmlDocument.xmlRoot.xmlName == "validator") {
			createValidator(xmlDocument.xmlRoot);
		}

	}

	private void function createValidator(required xml node) {

		// this should be a validator node with a name attribute
		var validator = variables.context.createValidator(arguments.node.xmlAttributes.name);

		var ruleSetNodes = arguments.node.xmlChildren; // ruleset nodes
		for (var ruleSetNode in ruleSetNodes) {
			var ruleSetName = ruleSetNode.xmlAttributes.name;
			var fieldName = ruleSetName; // if no field attribute is present, we use the rule set name for the field name
			if (StructKeyExists(ruleSetNode.xmlAttributes, "field")) {
				fieldName = ruleSetNode.xmlAttributes.field;
			}
			var mustPass = []; // array of rule set names to pass before this rule set is processed
			if (StructKeyExists(ruleSetNode.xmlAttributes, "mustpass")) {
				mustPass = ListToArray(ruleSetNode.xmlAttributes.mustpass);
			}

			var ruleSet = variables.context.createRuleSet();
			createRulesFromChildNodes(ruleSetNode, ruleSet, fieldName);

			validator.addRuleSet(ruleSet, ruleSetName, fieldName, mustPass);
		}

	}

	private void function createRulesFromChildNodes(required xml node, required RuleSet ruleSet, required string fieldName, datatype = "string") {

		// if we encounter a validity rule, we change the datatype so we can create rules specific to the datatype
		local.datatype = arguments.datatype;

		var ruleNodes = arguments.node.xmlChildren;
		for (var ruleNode in ruleNodes) {
			var xmlAttributes = ruleNode.xmlAttributes;

			var message = "";
			if (StructKeyExists(xmlAttributes, "message")) {
				message = xmlAttributes.message;
				silent = false;
			}
			var mask = "";
			if (StructKeyExists(xmlAttributes, "mask")) {
				mask = xmlAttributes.mask;
			}

			var rule = createRuleFromNode(ruleNode, arguments.fieldName, local.datatype);

			// check if this is a validity rule; if so, remember the datatype for further rules
			if (ruleNode.xmlName == "valid") {
				switch (xmlAttributes.type) {

					case "integer":
					case "numeric":
						local.datatype = "numeric";
						break;

					case "time":
					case "date":
					case "datetime":
						local.datatype = "datetime";
						break;

					default:
						local.datatype = "string";
						break;

				}
			}

			arguments.ruleSet.addRule(rule, message, mask);
			if (!ArrayIsEmpty(ruleNode.xmlChildren)) {
				// this rule has child rules, to be tested when the rule passes
				// create a RuleSet or an EachRuleSet
				// an EachRuleSet is a RuleSet that tests its rules against all elements in a given set, as opposed to only a single value
				if (ruleNode.xmlName == "each") {
					// check the aggregate attribute
					var aggregate = StructKeyExists(ruleNode.xmlAttributes, "aggregate") ? ruleNode.xmlAttributes.aggregate : false;
					local.ruleSet = variables.context.createEachRuleSet(aggregate);
					// the EachRuleSet needs the field name to access the set to test against
					local.ruleSet.setField(arguments.fieldName);
				} else {
					local.ruleSet = variables.context.createRuleSet();
				}

				createRulesFromChildNodes(ruleNode, local.ruleSet, arguments.fieldName, local.datatype);
				// by adding the rule set immediately after the rule, the containg rule set knows that the rule contains child rules
				arguments.ruleSet.addRuleSet(local.ruleSet);
			}
		}

	}

	private Rule function createRuleFromNode(required xml node, required string fieldName, datatype = "string") {

		var ruleType = arguments.node.xmlName;
		// check if it is a negation; in this case the node name starts with "not-"
		var negation = false;
		if (ListFirst(ruleType, "-") == "not") {
			negation = true;
			ruleType = ListRest(ruleType, "-");
		}

		var xmlAttributes = arguments.node.xmlAttributes;
		var caseSensitive = StructKeyExists(xmlAttributes, "caseSensitive") && xmlAttributes.caseSensitive;

		var rule = JavaCast("null", 0);

		switch (ruleType) {
			case "exist":
			case "each":
				// EachRuleSet is a RuleSet
				// we return a simple rule after which we can add the EachRuleSet, to prevent an error if the each node is the first node (rule sets can only be added after a rule)
				rule = variables.context.createExistRule();
				break;

			case "nonempty":
				rule = variables.context.createNonEmptyRule();
				break;

			case "valid":
				rule = variables.context.createValidRule(xmlAttributes.type);
				break;

			case "satisfy":
				rule = variables.context.createSatisfyRule(xmlAttributes.condition);
				break;

			case "contain":
				rule = variables.context.createContainRule(xmlAttributes.value, caseSensitive);
				break;

			case "endwidth":
				rule = variables.context.createEndWithRule(xmlAttributes.value, caseSensitive);
				break;

			case "startwith":
				rule = variables.context.createStartWithRule(xmlAttributes.value, caseSensitive);
				break;

			case "match":
				rule = variables.context.createMatchRule(xmlAttributes.pattern);
				break;

			case "element":
				rule = variables.context.createElementRule(xmlAttributes.set, caseSensitive);
				break;

			case "intersection":
				rule = variables.context.createIntersectionRule(xmlAttributes.set, caseSensitive);
				break;

			case "subset":
				rule = variables.context.createSubsetRule(xmlAttributes.set, caseSensitive);
				break;

			case "superset":
				rule = variables.context.createSupersetRule(xmlAttributes.set, caseSensitive);
				break;

			case "distinct":
				rule = variables.context.createDistinctRule(caseSensitive);
				break;

			case "equal":
				if (StructKeyExists(xmlAttributes, "value")) {
					// create a rule depending on the datatype
					switch (arguments.datatype) {
						case "string":
							rule = variables.context.createEqualStringRule(xmlAttributes.value, caseSensitive);
							break;

						case "numeric":
							rule = variables.context.createEqualNumericRule(xmlAttributes.value);
							break;

						case "datetime":
							rule = variables.context.createEqualDateTimeRule(xmlAttributes.value);
							break;
					}
				} else if (StructKeyExists(xmlAttributes, "set")) {
					rule = variables.context.createEqualSetRule(xmlAttributes.set, caseSensitive);
				}
				break;

			case "minimum":
				if (StructKeyExists(xmlAttributes, "value")) {
					// create a rule depending on the datatype
					switch (arguments.datatype) {
						case "numeric":
						case "string":
							rule = variables.context.createMinimumNumericRule(xmlAttributes.value);
							break;

						case "datetime":
							rule = variables.context.createMinimumDateTimeRule(xmlAttributes.value);
							break;
					}
				} else if (StructKeyExists(xmlAttributes, "length")) {
					rule = variables.context.createMinimumLengthRule(xmlAttributes.length);
				} else if (StructKeyExists(xmlAttributes, "count")) {
					rule = variables.context.createMinimumCountRule(xmlAttributes.count);
				}
				break;

			case "maximum":
				if (StructKeyExists(xmlAttributes, "value")) {
					// create a rule depending on the datatype
					switch (arguments.datatype) {
						case "numeric":
						case "string":
							rule = variables.context.createMaximumNumericRule(xmlAttributes.value);
							break;

						case "datetime":
							rule = variables.context.createMaximumDateTimeRule(xmlAttributes.value);
							break;
					}
				} else if (StructKeyExists(xmlAttributes, "length")) {
					rule = variables.context.createMaximumLengthRule(xmlAttributes.length);
				} else if (StructKeyExists(xmlAttributes, "count")) {
					rule = variables.context.createMaximumCountRule(xmlAttributes.count);
				}
				break;

			case "rule":
				// create an instance of the component, and pass all attributes as arguments except the default attributes
				var argumentCollection = {};
				// workaround for Railo bug 1798, can't use StructCopy to copy xml structs
				for (var attribute in xmlAttributes) {
					if (!ArrayContains(["message", "component", "field", "mask"], attribute)) {
						argumentCollection[attribute] = xmlAttributes[attribute];
					}
				}
				rule = new "#xmlAttributes.component#"(argumentCollection = argumentCollection);
				break;

		}

		if (!StructKeyExists(local, "rule")) {
			Throw(type = "cflow.validation", message = "Invalid rule '#arguments.node.xmlName#'");
		}

		// tell the rule how to obtain the value to test
		// by default it is the field name of the rule set, passed in as the fieldName argument
		// a field attribute on the rule node overrides this
		if (StructKeyExists(xmlAttributes, "field")) {
			// field contains the field name to get the value from
			rule.setField(xmlAttributes.field);
		} else {
			// default: use the fieldName passed in
			rule.setField(arguments.fieldName);
		}

		if (ruleType != "each") {
			if (negation) {
				rule = variables.context.createNegateRule(rule);
			}
		}

		return rule;
	}

}