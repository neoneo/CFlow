component ValidRule implements="Rule" {

	public void function init(required string type) {

		variables.type = arguments.type;

	}

	public boolean function test(required struct data, required string fieldName) {

		var result = false;
		var value = arguments.data[arguments.fieldName];

		switch (variables.type) {

			case "integer":
			case "float":
				result = IsValid(variables.type, value);
				if (result) {
					arguments.data[arguments.fieldName] = Val(value);
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
				value = ListChangeDelims(value, ":", ".");
			case "date":
			case "datetime":
				result = LSIsDate(value);
				if (result) {
					arguments.data[arguments.fieldName] = LSParseDateTime(value);
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