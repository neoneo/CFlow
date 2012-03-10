/**
 * Checks whether the field value is an element in the set.
 **/
component ElementRule extends="SetRule" {

	public boolean function test(required struct data, required string fieldName) {
		return isElement(arguments.data[arguments.fieldName], getParameterValue(arguments.data));
	}

}