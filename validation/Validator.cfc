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

component Validator {

	variables.ruleSets = {};
	variables.names = [];

	public void function addRuleSet(required RuleSet ruleSet, required string name, string fieldName = "", array mustPass = []) {

		local.fieldName = arguments.fieldName;
		if (Len(local.fieldName) == 0) {
			local.fieldName = arguments.name;
		}

		variables.ruleSets[arguments.name] = {
			instance = arguments.ruleSet,
			field = local.fieldName,
			mustPass = arguments.mustPass
		};
		ArrayAppend(variables.names, arguments.name);

	}

	public Result function validate(required struct data) {

		var result = new Result();

		for (var name in variables.names) {
			var info = variables.ruleSets[name];
			// check if there are other rule sets that must have been passed successfully
			var perform = ArrayIsEmpty(info.mustPass);
			if (!perform) {
				// rule sets in the mustPass array must have been passed (and therefore tested)
				perform = true;
				for (var name in info.mustPass) {
					if (!result.isPassed(name)) {
						perform = false;
						break;
					}
				}
			}

			if (perform) {
				var messages = info.instance.validate(arguments.data, info.field);
				result.addMessages(info.field, messages);
			}
		}

		return result;
	}

}