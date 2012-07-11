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

component MatchRule extends="Rule" {

	public void function init(required string pattern) {
		variables.pattern = arguments.pattern;
	}

	public boolean function test(required struct data) {
		return IsValid("regex", arguments.data[variables.fieldName], variables.pattern);
	}

	public string function script() {

		// escape slashes
		var pattern = Replace(variables.pattern, "/", "\/", "all");
		// IsValid() only matches complete strings, so adjust the pattern for this if necessary
		if (Left(pattern, 1) != "^") {
			pattern = "^" & pattern;
		}
		if (Right(pattern, 1) != "$") {
			pattern &= "$";
		}

		return "
			function (data) {
				return /#pattern#/.test(data.#variables.fieldName#);
			}
		";
	}

}