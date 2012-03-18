/**
 * Checks whether the field value contains a superset of the given set, when interpreted as a list.
 **/
component SupersetRule extends="SetRule" {

	public boolean function test(required struct data) {
		// the parameter set should be a subset of the set in the field
		return isSubset(getParameterValue(arguments.data), toArray(getValue(arguments.data)));
	}

}