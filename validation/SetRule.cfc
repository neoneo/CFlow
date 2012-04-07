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
 * Abstract implementation for rules that act on sets (arrays).
 **/
component SetRule extends="Rule" {

	public void function init(required string value, boolean caseSensitive = false) {
		variables.parameter = new SetParameter(arguments.value);
		variables.caseSensitive = arguments.caseSensitive;
	}

	public string function formatParameterValue(required struct data, string mask = "") {
		return ArrayToList(getParameterValue(arguments.data), ", ");
	}

	private array function getParameterValue(required struct data) {
		return variables.parameter.getValue(arguments.data);
	}

	/**
	 * Determines whether a set is a subset of another.
	 **/
	private boolean function isSubset(required array set, required array superset) {

		var size = ArrayLen(arguments.set);

		// check if all elements in set occur in superset
		var i = 1;
		while (i <= size && isElement(arguments.set[i], arguments.superset)) {
			i++;
		}

		return i > size;
	}

	/**
	 * Determines whether the value is an element of the set.
	 **/
	private boolean function isElement(required string value, required array set) {

		var result = false;

		if (variables.caseSensitive) {
			result = ArrayFind(arguments.set, arguments.value) > 0;
		} else {
			result = ArrayFindNoCase(arguments.set, arguments.value) > 0;
		}

		return result;
	}

}