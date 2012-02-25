/**
 * Checks whether the field value is a subset of the given set, when interpreted as a list.
 **/
component SubsetRule extends="SetRule" {

	public boolean function test(required struct data, required string fieldName) {
		return isSubset(toArray(arguments.data[arguments.fieldName]), getParameterValue());
	}

}