/**
 * Checks whether the field contains a set that has a non-empty intersection with the set parameter.
 * In other words, at least one element from the field set must appear in the set parameter.
 **/
component IntersectionRule extends="SetRule" {

	public boolean function test(required struct data) {

		var result = false;

		var set = toArray(getValue(arguments.data));
		var size = ArrayLen(set);
		var compareSet = getParameterValue(arguments.data);

		var i = 1;
		while (!result && i <= size) {
			if (isElement(set[i], compareSet)) {
				result = true;
			}
			i++;
		}

		return result;
	}

}