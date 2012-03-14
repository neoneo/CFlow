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

	public void function setValue(required string expression, boolean evaluate = false) {

		// the expression can be a date, a variable name or a date arithmetic expression
		// an arithmetic expression should be of the form [date or date variable] [+ or -] [number and unit]
		// explicit dates should use slashes

		var date = Trim(ListFirst(arguments.expression, "+-"));
		if (IsDate(date)) {
			variables.date = ParseDateTime(date);
			variables.evaluate = false;
		} else {
			variables.date = date;
			variables.evaluate = true;
		}

		var partCount = ListLen(arguments.expression, "+-");
		// this should be 1 or 2
		if (partCount == 1) {
			// no date arithmetic
			variables.arithmetic = false;
		} else if (partCount == 2) {
			variables.arithmetic = true;
			var sign = Mid(arguments.expression, FindOneOf("+-", arguments.expression, Len(date)), 1); // start looking for + or - after the date value
			var incrementUnit = Trim(ListLast(arguments.expression, "+-"));
			variables.datepart = variables.dateparts[Right(incrementUnit, 1)]; // read the ColdFusion datepart to use in the DateAdd() function
			variables.increment = Val(sign & incrementUnit);
		} else {
			Throw(type = "cflow.validation", message = "Expression '#arguments.expression#' is not a valid date/time expression", detail = "If you pass in date strings, use slashes as the datepart separator");
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