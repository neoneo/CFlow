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

/**
 * Abstracts access to parameter values.
 * The setValue() method accepts any string expression. If the expression begins with a %, the expression (less the %) will be evaluated.
 * The getValue() method accepts a data struct that provides context for the expression (if evaluated), and returns the result.
 * If no evaluation should occur, this component just stores and returns the expression as is.
 **/
component Parameter {

	public void function setValue(required string expression) {

		variables.evaluate = false;

		local.expression = arguments.expression;
		if (Left(local.expression, 1) == "%") {
			variables.evaluate = true;
			RemoveChars(local.expression, 1, 1);
			if (Left(local.expression, 1) == "%") {
				variables.evaluate = false;
			}
		}

		if (variables.evaluate) {
			variables.expression = new cflow.util.Evaluator(local.expression);
		} else {
			variables.expression = local.expression;
		}

	}

	public any function getValue(required struct data) {

		var value = JavaCast("null", 0);

		if (variables.evaluate) {
			value = variables.expression.execute(arguments.data);
		} else {
			value = variables.expression;
		}

		return value;
	}

}