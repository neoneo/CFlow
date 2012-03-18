/**
 * Checks whether the field value is an element in the set.
 **/
component ElementRule extends="SetRule" {

	public boolean function test(required struct data) {
		return isElement(getValue(arguments.data), getParameterValue(arguments.data));
	}

}