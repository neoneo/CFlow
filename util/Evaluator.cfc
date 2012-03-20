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

component Evaluator {

	public void function init(required string expression) {

		// replace all ColdFusion operators by their script counterparts
		var result = ReplaceList(" " & arguments.expression & " ", " eq , lt , lte , gt , gte , neq , not , and , or , mod "," == , < , <= , > , >= , != ,!, && , || , % ");
		// add spaces between parentheses so it's easy to discriminate between variables and function names or arguments
		result = ReplaceList(result, "(,)", "( , )");
		result = Replace(result, ",", " , ", "all"); // surround commas with spaces too
		// interpret remaining alphanumeric terms without a parenthesis as a field name (which will be available in arguments.data)
		result = REReplaceNoCase(" " & result & " ", " ([a-z_]+[a-z0-9_]*)(?!\() ", " arguments.data.\1 ", "all");
		// remove excess whitespace
		result = REReplace(Trim(result), "[\s]+", " ", "all");

		variables.expression = result;

	}

	/**
	 * Returns the value of the expression after evaluation.
	 **/
	public any function execute(struct data) {
		return Evaluate(variables.expression);
	}

}