component XmlReader accessors="true" {

	property name="context" type="Context" getter="false";

	public void function read(required string path) {

		var path = ExpandPath(arguments.path);
		var list = DirectoryList(path, true, "name", "*.xml");

		for (var fileName in list) {
			readFile(path & "/" & fileName);
		}

	}

	private void function readFile(required string path) {

		var content = FileRead(arguments.path);
		var xmlDocument = XmlParse(content, false);

		// the root element should be validator
		if (xmlDocument.xmlRoot.xmlName eq "validator") {
			createValidator(xmlDocument.xmlRoot);
		}

	}

	private void function createValidator(required xml node) {

		// this should be a validator node with a name attribute
		var validator = variables.context.createValidator(arguments.node.xmlAttributes.name);

		var ruleSetNodes = arguments.node.xmlChildren; // ruleset nodes
		for (var ruleSetNode in ruleSetNodes) {
			var ruleSet = variables.context.createRuleSet();
			createRulesFromChildNodes(ruleSetNode, ruleSet);

			var ruleSetName = ruleSetNode.xmlAttributes.name;
			var fieldName = ruleSetName; // if no field attribute is present, we take the rule set name for the field name
			if (StructKeyExists(ruleSetNode.xmlAttributes, "field")) {
				fieldName = ruleSetNode.xmlAttributes.field;
			}
			var mustPass = [];
			if (StructKeyExists(ruleSetNode.xmlAttributes, "mustpass")) {
				mustPass = ListToArray(ruleSetNode.xmlAttributes.mustpass);
			}

			validator.addRuleSet(ruleSet, ruleSetName, fieldName, mustPass);
		}

	}

	private void function createRulesFromChildNodes(required xml node, required RuleSet ruleSet, datatype = "string") {

		// if we encounter a valid rule, we change the datatype so we can create rules specific to the datatype
		// this mechanism is based on the assumption that there will be only one valid rule
		var datatype = arguments.datatype;

		var ruleNodes = arguments.node.xmlChildren;
		for (var ruleNode in ruleNodes) {
			var silent = StructKeyExists(ruleNode.xmlAttributes, "silent") && ruleNode.xmlAttributes.silent;
			var message = "";
			if (StructKeyExists(ruleNode.xmlAttributes, "message")) {
				message = ruleNode.xmlAttributes.message;
			}
			var mask = "";
			if (StructKeyExists(ruleNode.xmlAttributes, "mask")) {
				mask = ruleNode.xmlAttributes.mask;
			}

			var rule = createRuleFromNode(ruleNode, datatype);
			// check if this is a valid rule; if so, remember the datatype for further rules
			if (IsInstanceOf(rule, "ValidRule")) {
				switch (ruleNode.xmlAttributes.type) {

					case "integer":
					case "numeric":
						datatype = "numeric";
						break;

					case "time":
					case "date":
					case "datetime":
						datatype = "datetime";
						break;

					default:
						datatype = "string";
						break;

				}
			}

			arguments.ruleSet.addRule(rule, message, silent, mask);
			if (!ArrayIsEmpty(ruleNode.xmlChildren)) {
				// this rule has child rules, to be tested when the rule passes
				var ruleSet = variables.context.createRuleSet();
				createRulesFromChildNodes(ruleNode, ruleSet, datatype);
				// by adding the rule set immediately after the rule, the containg rule set knows that the rule set contains child rules
				arguments.ruleSet.addRuleSet(ruleSet);
			}
		}

	}

	private Rule function createRuleFromNode(required xml node, datatype = "string") {

		var ruleType = arguments.node.xmlName;
		// check if it is a negation; in this case the node name starts with "not-"
		var negation = false;
		if (ListFirst(ruleType, "-") eq "not") {
			negation = true;
			ruleType = ListRest(ruleType, "-");
		}

		var xmlAttributes = arguments.node.xmlAttributes;
		var eval = StructKeyExists(xmlAttributes, "evaluate") && xmlAttributes.evaluate;
		var matchCase = StructKeyExists(xmlAttributes, "matchcase") && xmlAttributes.matchcase;

		var rule = JavaCast("null", 0);

		switch (ruleType) {
			case "exist":
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
				rule = variables.context.createContainRule(xmlAttributes.value, eval, matchCase);
				break;

			case "endwidth":
				rule = variables.context.createEndWithRule(xmlAttributes.value, eval, matchCase);
				break;

			case "startwith":
				rule = variables.context.createStartWithRule(xmlAttributes.value, eval, matchCase);
				break;

			case "match":
				rule = variables.context.createMatchRule(xmlAttributes.pattern);
				break;

			case "element":
				rule = variables.context.createElementRule(xmlAttributes.set, eval, matchCase);
				break;

			case "intersection":
				rule = variables.context.createIntersectionRule(xmlAttributes.set, eval, matchCase);
				break;

			case "subset":
				rule = variables.context.createSubsetRule(xmlAttributes.set, eval, matchCase);
				break;

			case "superset":
				rule = variables.context.createSupersetRule(xmlAttributes.set, eval, matchCase);
				break;

			case "equal":
				if (StructKeyExists(xmlAttributes, "value")) {
					// create a rule depending on the datatype
					switch (arguments.datatype) {
						case "string":
							rule = variables.context.createEqualStringRule(xmlAttributes.value, eval, matchCase);
							break;

						case "numeric":
							rule = variables.context.createEqualNumericRule(xmlAttributes.value, eval);
							break;

						case "datetime":
							rule = variables.context.createEqualDateTimeRule(xmlAttributes.value, eval);
							break;
					}
				} else if (StructKeyExists(xmlAttributes, "set")) {
					rule = variables.context.createEqualSetRule(xmlAttributes.set, eval, matchCase);
				}
				break;

			case "minimum":
				if (StructKeyExists(xmlAttributes, "value")) {
					// create a rule depending on the datatype
					switch (arguments.datatype) {
						case "numeric":
						case "string":
							rule = variables.context.createMinimumNumericRule(xmlAttributes.value, eval);
							break;

						case "datetime":
							rule = variables.context.createMinimumDateTimeRule(xmlAttributes.value, eval);
							break;
					}
				} else if (StructKeyExists(xmlAttributes, "length")) {
					rule = variables.context.createMinimumLengthRule(xmlAttributes.length, eval);
				} else if (StructKeyExists(xmlAttributes, "count")) {
					rule = variables.context.createMinimumCountRule(xmlAttributes.count, eval);
				}
				break;

			case "maximum":
				if (StructKeyExists(xmlAttributes, "value")) {
					// create a rule depending on the datatype
					switch (arguments.datatype) {
						case "numeric":
						case "string":
							rule = variables.context.createMaximumNumericRule(xmlAttributes.value, eval);
							break;

						case "datetime":
							rule = variables.context.createMaximumDateTimeRule(xmlAttributes.value, eval);
							break;
					}
				} else if (StructKeyExists(xmlAttributes, "length")) {
					rule = variables.context.createMaximumLengthRule(xmlAttributes.length, eval);
				} else if (StructKeyExists(xmlAttributes, "count")) {
					rule = variables.context.createMaximumCountRule(xmlAttributes.count, eval);
				}
				break;

			case "rule":
				// create an instance of the component, and pass all attributes as arguments except the default attributes
				var argumentCollection = {};
				// workaround for Railo bug 1798, can't use StructCopy to copy xml structs
				for (var attribute in xmlAttributes) {
					if (!ArrayContains(["message", "silent", "component"], attribute)) {
						argumentCollection[attribute] = xmlAttributes[attribute];
					}
				}
				rule = new "#xmlAttributes.component#"(argumentCollection = argumentCollection);
				break;

		}

		if (!StructKeyExists(local, "rule")) {
			Throw(type = "cflow.validation", message = "Invalid rule '#arguments.node.xmlName#'");
		}

		if (negation) {
			rule = variables.context.createNegateRule(rule);
		}

		return rule;
	}

}