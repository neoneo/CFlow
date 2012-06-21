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

component DateTimeParameter {

	// translation from accepted dateparts to ColdFusion dateparts
	variables.dateparts = {
		"y" = "yyyy",
		"q" = "q",
		"m" = "m",
		"d" = "d",
		"w" = "ww",
		"h" = "h",
		"n" = "n",
		"s" = "s",
		"l" = "l"
	};

	public void function init(required string expression) {

		// the expression can be a date, a variable name or a date arithmetic expression
		// an arithmetic expression should be of the form [date or date variable] [+ or -] [number and unit]
		// explicit dates should use slashes

		// a percentage sign is not needed for this parameter, but to be consequent its use is allowed
		// just remove it
		local.expression = arguments.expression;
		if (Left(local.expression, 1) == "%") {
			local.expression = RemoveChars(local.expression, 1, 1);
		}

		var date = Trim(ListFirst(local.expression, "+-"));
		if (IsDate(date)) {
			variables.date = ParseDateTime(date);
			variables.evaluate = false;
		} else {
			variables.date = date;
			variables.evaluate = true;
		}

		var partCount = ListLen(local.expression, "+-");
		// this should be 1 or 2
		if (partCount == 1) {
			// no date arithmetic
			variables.arithmetic = false;
		} else if (partCount == 2) {
			variables.arithmetic = true;
			var sign = Mid(local.expression, FindOneOf("+-", local.expression, Len(date)), 1); // start looking for + or - after the date value
			var incrementUnit = Trim(ListLast(local.expression, "+-"));
			variables.datepart = variables.dateparts[Right(incrementUnit, 1)]; // read the ColdFusion datepart to use in the DateAdd() function
			variables.increment = Val(sign & incrementUnit);
		} else {
			Throw(
				type = "cflow.validation",
				message = "Expression '#local.expression#' is not a valid date/time expression",
				detail = "If you pass in date literals, use slashes as the datepart separator"
			);
		}

	}

	public date function getValue(required struct data) {

		var value = JavaCast("null", 0);

		if (variables.evaluate) {
			switch (variables.date) {
				case "now":
					value = Now();
					break;

				case "today":
					// use today's date with the time set at 00:00:00
					value = CreateDate(Year(Now()), Month(Now()), Day(Now()));
					break;

				case "year":
				case "quarter1":
					value = CreateDate(Year(Now()), 1, 1);
					break;

				case "quarter2":
					value = CreateDate(Year(Now()), 4, 1);
					break;

				case "quarter3":
					value = CreateDate(Year(Now()), 7, 1);
					break;

				case "quarter4":
					value = CreateDate(Year(Now()), 10, 1);
					break;

				default:
					// variables.date contains a variable name
					value = arguments.data[variables.date]; // this should already be a valid date
					break;
			}
		} else {
			// variables.date is a date
			value = variables.date;
		}

		if (variables.arithmetic) {
			value = DateAdd(variables.datepart, variables.increment, value);
		}

		return value;
	}

}