component ValidRule implements="Rule" accessors="true" {

	property name="field" type="string" required="true";
	property name="parameter" type="string" required="true";

	public boolean function test(required struct data) {

		var result = false;
		var value = arguments.data[getField()];

		switch (getParameter()) {

			case "guid":
			case "integer":
			case "float":
			case "boolean":
			case "email":
			case "url":
			case "creditcard":
				result = IsValid(getParameter(), value);
				break;

			case "date":
			case "datetime":
				result = IsDate(value) || value == "now";
				break;

			case "time":
				value = ListChangeDelims(value, ":", ".");
				result = IsDate(value) || value == "now";
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