/**
 * Checks whether the field value is a subset of the given set, when interpreted as a list.
 **/
component SubsetRule implements="Rule" {

	public void function init(required array set, string delimiter = ",") {
		variables.set = arguments.set;
		variables.delimiter = arguments.delimiter;
	}

	public boolean function test(required struct data, required string fieldName) {

		var subset = ListToArray(arguments.data[arguments.fieldName], variables.delimiter);
		var size = ArrayLen(subset);

		var i = 1;
		while (i <= size && ArrayContains(variables.set, subset[i])) {
			i++;
		}

		return i > size;
	}

}