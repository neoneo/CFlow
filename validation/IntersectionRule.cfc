/**
 * Checks whether the field contains a set that has a non-empty intersection with the given set.
 * In other words, at least one element from the field set must appear in the given set.
 **/
component IntersectionRule implements="Rule" {

	public void function init(required array set, string delimiter = ",") {
		variables.set = arguments.set;
		variables.delimiter = arguments.delimiter;
	}

	public boolean function test(required struct data, required string fieldName) {

		var result = false;
		var set = ListToArray(arguments.data[arguments.fieldName], variables.delimiter);
		var size = ArrayLen(set);

		var i = 1;
		while (!result && i <= size) {
			if (ArrayContains(variables.set, set[i])) {
				result = true;
			}
			i++;
		}

		return result;
	}

}