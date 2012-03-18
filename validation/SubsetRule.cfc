/**
 * Checks whether the field value is a subset of the given set, when interpreted as a list.
 **/
component SubsetRule extends="SetRule" {

	public boolean function test(required struct data) {
		return isSubset(toArray(getValue(arguments.data)), getParameterValue(arguments.data));
	}

}