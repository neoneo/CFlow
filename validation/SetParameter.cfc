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

	variables.hasValue = false; // whether an array was passed in

	public void function setValue(required any value) {

		if (IsArray(arguments.value)) {
			variables.value = arguments.value;
			variables.hasValue = true;
		} else {
			super.setValue(arguments.value);
		}

	}

	public array function getValue(required struct data) {

		var value = JavaCast("null", 0);

		if (variables.hasValue) {
			value = variables.value;
		} else {
			value = super.getValue(arguments.data);
			if (!IsArray(value)) {
				// interpret the value as a comma separated list
				value = ListToArray(value);
			}
		}

		return value;
	}

}