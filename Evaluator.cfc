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

		var result = " " & arguments.expression & " ";
		// replace ColdFusion operators by their script counterparts
		result = ReplaceList(result, " eq , lt , lte , gt , gte , neq , not , and , or , mod ", " == , < , <= , > , >= , != , !, && , || , % ");
		// interpret remaining alphanumeric terms without a parenthesis as a field name (which will be available in arguments.data)
		// explanation:
		// before the variable name there must be a space, or one of ( , + - * / & ^ = < > ! | %
		// the variable name must be followed by one of those characters, except (, and including . )
		result = REReplaceNoCase(result, "([ (,+*/&^=<>!|%-])([a-z_]+[a-z0-9_]*)([ )\.,+*/&^=<>!|%-])", "\1arguments.data.\2\3", "all");

		variables.expression = Trim(result);

	}

	/**
	 * Returns the value of the expression after evaluation.
	 **/
	public any function execute(required struct data) {
		return Evaluate(variables.expression);
	}

	public string function getExpression() {
		return variables.expression;
	}

}