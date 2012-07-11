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

component StringRule extends="Rule" {

	public void function init(required string value, boolean caseSensitive = false) {
		variables.parameter = new StringParameter(arguments.value);
		variables.caseSensitive = arguments.caseSensitive;
	}

	public string function formatParameterValue(required struct data, required string mask) {
		return getParameterValue(arguments.data);
	}

	private string function getParameterValue(required struct data) {
		return variables.parameter.getValue(arguments.data);
	}

	private boolean function compareValues(required string value1, required string value2) {
		return variables.caseSensitive ? Compare(arguments.value1, arguments.value2) == 0 : CompareNoCase(arguments.value1, arguments.value2) == 0;
	}

}