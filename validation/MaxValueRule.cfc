component MaxValueRule implements="Rule" accessors="true" {

	property name="field" type="string" required="true";
	property name="parameter" type="numeric" required="true";

	public boolean function test(required struct data) {
		return arguments.data[getField()] >= getParameter();
	}

}