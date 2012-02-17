/**
 * Checks whether the field value contains a superset of the given set, when interpreted as a list.
 **/
component SupersetRule implements="Rule" {

	public void function init(required array set, string delimiter = ",") {
		variables.set = arguments.set;
		variables.delimiter = arguments.delimiter;
	}

	public boolean function test(required struct data, required string fieldName) {

		var superset = ListToArray(arguments.data[arguments.fieldName], variables.delimiter);
		var size = ArrayLen(variables.set);

		var i = 1;
		while (i <= size && ArrayContains(superset, variables.set[i])) {
			i++;
		}

		return i > size;
	}

}