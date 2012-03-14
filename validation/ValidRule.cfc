component ValidRule implements="Rule" {

	public void function init(required string type) {

		variables.type = arguments.type;

	}

	public boolean function test(required struct data, required string fieldName) {

		var result = false;
		var value = arguments.data[arguments.fieldName];

		switch (variables.type) {

			case "numeric":
			case "integer":
				if (IsNumeric(value)) {
					value = Val(value);
				} else if (LSIsNumeric(value)) {
					value = LSParseNumber(value);
				}
				result = IsValid(variables.type, value);
				if (result) {
					arguments.data[arguments.fieldName] = value;
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
				if (IsDate(value)) {
					result = true;
					value = ParseDateTime(value);
				} else if (LSIsDate(value)) {
					result = true;
					value = LSParseDateTime(value);
				}
				if (result) {
					arguments.data[arguments.fieldName] = value;
				}
				break;

			case "website":
				result = IsValid("url", value) && REFind("^http[s]?://", value) == 1;
				break;

			case "color":
				result = IsValid("regex", value,"^([0-9A-Fa-f]){6}$");
				break;

			default:
				result = IsInstanceOf(value, getParameter());
				break;

		}

		return result;
	}

}