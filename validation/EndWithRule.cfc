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

component EndWithRule extends="StringRule" {

	public boolean function test(required struct data) {

		var compareValue = getParameterValue(arguments.data);
		var value = Right(getValue(arguments.data), Len(compareValue));

		return compareValues(value, compareValue);
	}

	public string function script() {

		var comparison = variables.caseSensitive ? "value.indexOf(parameterValue)" : "value.toLowerCase().indexOf(parameterValue.toLowerCase())";

		return "
			function (data) {
				var value = data.#variables.fieldName#;
				var parameterValue = (#variables.parameter.script()#)(data);

				return #comparison# === value.length - parameterValue.length;
			}
		";
	}

}