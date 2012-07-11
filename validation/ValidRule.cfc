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

component ValidRule extends="Rule" {

	public void function init(required string type) {
		variables.type = arguments.type;
	}

	public boolean function test(required struct data) {

		var result = false;
		var value = arguments.data[variables.fieldName];

		switch (variables.type) {

			case "numeric":
			case "integer":
				if (LSIsNumeric(value)) {
					value = LSParseNumber(value);
				} else if (IsNumeric(value)) {
					value = Val(value);
				}
				result = StructKeyExists(local, "value") && IsValid(variables.type, value);
				if (result) {
					arguments.data[variables.fieldName] = value;
				}
				break;

			case "guid":
			case "boolean":
			case "email":
			case "url":
			case "creditcard":
				result = IsValid(variables.type, value);
				break;

			case "time":
				value = ListChangeDelims(value, ":", "."); // also accept . as a delimiter
			case "date":
			case "datetime":
				if (LSIsDate(value)) {
					result = true;
					value = LSParseDateTime(value);
				} else if (IsDate(value)) {
					result = true;
					value = ParseDateTime(value);
				}
				if (result) {
					arguments.data[variables.fieldName] = value;
				}
				break;

			case "website":
				result = IsValid("url", value) && REFind("^http[s]?://", value) == 1;
				break;

			case "color":
				result = IsValid("regex", value,"^([0-9A-Fa-f]){6}$");
				break;

		}

		return result;
	}

	public string function script() {

		var expression = "";
		/*switch (variables.type) {

			case "numeric":
			case "integer":
				if (LSIsNumeric(value)) {
					value = LSParseNumber(value);
				} else if (IsNumeric(value)) {
					value = Val(value);
				}
				result = StructKeyExists(local, "value") && IsValid(variables.type, value);
				if (result) {
					arguments.data[variables.fieldName] = value;
				}
				break;

			case "guid":
			case "boolean":
			case "email":
			case "url":
			case "creditcard":
				result = IsValid(variables.type, value);
				break;

			case "time":
				value = ListChangeDelims(value, ":", "."); // also accept . as a delimiter
			case "date":
			case "datetime":
				if (LSIsDate(value)) {
					result = true;
					value = LSParseDateTime(value);
				} else if (IsDate(value)) {
					result = true;
					value = ParseDateTime(value);
				}
				if (result) {
					arguments.data[variables.fieldName] = value;
				}
				break;

			case "website":
				result = IsValid("url", value) && REFind("^http[s]?://", value) == 1;
				break;

			case "color":
				result = IsValid("regex", value,"^([0-9A-Fa-f]){6}$");
				break;
		}*/

	}

}