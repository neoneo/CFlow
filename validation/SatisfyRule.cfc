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

component SatisfyRule extends="Rule" {

	public void function init(required string condition) {
		variables.evaluator = new cflow.util.Evaluator(arguments.condition);
	}

	public boolean function test(required struct data) {
		return variables.evaluator.execute(arguments.data);
	}

	public string function script() {

		// assume the expression used by the evaluator is correct Javascript
		var expression = Replace(variables.evaluator.getExpression(), "arguments.", "", "all");

		return "
			function (data) {
				return #expression#;
			}
		";
	}

}