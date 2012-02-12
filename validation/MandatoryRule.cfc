component MandatoryRule implements="Rule" accessors="true" {

	property name="field" type="string" required="true";

	public boolean function test(required struct data) {
		return StructKeyExists(arguments.data, getField()) && Len(arguments.data[getField()]) > 0;
	}

}