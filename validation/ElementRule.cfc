/**
 * Checks whether the field value is an element in the given set.
 **/
component ElementRule implements="Rule" {

	public void function init(required array set) {
		variables.set = arguments.set;
	}

	public boolean function test(required struct data, required string fieldName) {
		return ArrayContains(variables.set, arguments.data[arguments.fieldName]);
	}

}