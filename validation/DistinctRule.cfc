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
 * Checks whether all elements in the set are different.
 **/
component DistinctRule extends="Rule" {

	public void function init(boolean caseSensitive = false) {
		variables.caseSensitive = arguments.caseSensitive;
	}

	public boolean function test(required struct data) {

		var result = true;
		var set = toArray(getValue(arguments.data));
		var count = ArrayLen(set);

		var i = 1;
		while (result && i <= count - 1) {
			var j = i + 1;
			while (result && j <= count) {
				if (variables.caseSensitive) {
					result = Compare(ToString(set[i]), ToString(set[j])) != 0;
				} else {
					result = CompareNoCase(ToString(set[i]), ToString(set[j])) != 0;
				}
				j++;
			}
			i++;
		}

		return result;
	}

	public string function script() {

		var comparison = variables.caseSensitive ? "set[i] !== set[j]" : "set[i].toLowerCase() !== set[j].toLowerCase()";

		return "
			function (data) {
				var result = true;
				var set = data.#variables.fieldName#;
				var count = set.length;

				var i = 0;
				while (result && i < count - 1) {
					var j = i + 1;
					while (result && j < count) {
						result = #comparison#;
						j++;
					}
					i++;
				}

				return result;
			}
		";
	}

}