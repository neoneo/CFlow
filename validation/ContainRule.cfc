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

component ContainRule extends="StringRule" {

	public boolean function test(required struct data) {

		var value = getValue(arguments.data);
		var parameterValue = getParameterValue(arguments.data);
		var result = false;

		if (variables.caseSensitive) {
			result = Find(parameterValue, value) > 0;
		} else {
			result = FindNoCase(parameterValue, value) > 0;
		}

		return result;
	}

	public string function script() {

		var comparison = variables.caseSensitive ? "value.indexOf(parameterValue)" : "value.toLowerCase().indexOf(parameterValue.toLowerCase())";

		return "
			function (data) {
				var value = data.#variables.fieldName#;
				var parameterValue = (#variables.parameter.script()#)(data);

				return #comparison# > -1;
			}
		";
	}

}