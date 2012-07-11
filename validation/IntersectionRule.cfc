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
 * Checks whether the field contains a set that has a non-empty intersection with the set parameter.
 * In other words, at least one element from the field set must appear in the set parameter.
 **/
component IntersectionRule extends="SetRule" {

	public boolean function test(required struct data) {

		var result = false;

		var set = toArray(getValue(arguments.data));
		var size = ArrayLen(set);
		var compareSet = getParameterValue(arguments.data);

		var i = 1;
		while (!result && i <= size) {
			if (isElement(set[i], compareSet)) {
				result = true;
			}
			i++;
		}

		return result;
	}

	public string function script() {

		return "
			function (data) {
				var result = false;

				var set = data.#variables.fieldName#;
				var size = set.length;
				var compareSet = (#variables.parameter.script()#)(data);

				var i = 0;
				while (!result && i < size) {
					if (this.isElement(set[i], compareSet)) {
						result = true;
					}
					i++;
				}

				return result;
			}
		";

	}

}