component EqualSetRule extends="SetRule" {

	public boolean function test(required struct data) {

		var result = false;

		var set = toArray(getValue(arguments.data));
		var compareSet = getParameterValue(arguments.data);

		// we only reckon with sets that have unique values, so the number of elements of both sets is the same
		if (ArrayLen(set) == ArrayLen(compareSet)) {
			result = isSubset(set, compareSet);
		}

		return result;
	}

}