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

component Rule {

	variables.fieldName = "";

	/**
	 * Tests the rule for the given data struct. If the rule passes, returns true, otherwise false.
	 **/
	public boolean function test(required struct data) {
		Throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	/**
	 * Returns the script that performs the test on the client-side.
	 **/
	public string function script() {
		Throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	public void function setField(required string fieldName) {
		variables.fieldName = arguments.fieldName;
	}

	private any function getValue(required struct data) {
		return arguments.data[variables.fieldName];
	}

	// this method is included for cases where the tested value is a set
	private array function toArray(required any value) {

		var result = JavaCast("null", 0);
		if (IsArray(arguments.value)) {
			result = arguments.value;
		} else {
			result = ListToArray(arguments.value);
		}

		return result;
	}

}