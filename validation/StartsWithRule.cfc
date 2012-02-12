component StartsWithRule implements="Rule" {

	property name="field" type="string" required="true";
	property name="parameter" type="string" required="true";
	property name="isField" type="boolean" required="false" default="false";

	public boolean function test(required struct data) {

		var value = getParameter();
		if (getIsField()) {
			value = arguments.data[value];
		}

		return Left(arguments.data[getField()], Len(value)) == value;
	}

}