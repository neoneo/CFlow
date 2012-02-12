component MinLengthRule implements="Rule" accessors="true" {

	property name="field" type="string" required="true";
	property name="parameter" type="numeric" required="true";

	public boolean function test(required struct data) {
		return Len(arguments.data[getField()]) >= getParameter();
	}

}