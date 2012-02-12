component PatternRule implements="Rule" accessors="true" {

	property name="field" type="string" required="true";
	property name="parameter" type="string" required="true";

	public boolean function test(required struct data) {
		return IsValid("regex", arguments.data[getField()], getParameter());
	}

}