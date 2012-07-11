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

component SetParameter extends="Parameter" {

	public void function init(required any value) {

		if (IsArray(arguments.value)) {
			variables.value = arguments.value;
		} else {
			super.init(arguments.value);
		}

	}

	public array function getValue(required struct data) {

		var	value = super.getValue(arguments.data);
		if (!IsArray(value)) {
			// interpret the value as a comma separated list
			value = ListToArray(value);
		}

		return value;
	}

	public string function script() {

		var result = "";
		if (variables.evaluate) {
			result = super.script();
		} else {
			var expression = "";
			if (IsArray(variables.value)) {
				// convert the array to a Javascript array literal
				expression = SerializeJSON(variables.value);
			} else {
				// the value is a comma separated list
				expression = """" & Replace(variables.value, """", "\""", "all") & """" & ".split("","")";
			}

			result = "
				function (data) {
					return #expression#;
				}
			";
		}

		return result;
	}

}