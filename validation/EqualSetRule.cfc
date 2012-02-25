component EqualSetRule extends="SetRule" {

	public boolean function test(required struct data, required string fieldName) {

		var result = false;

		var set = toArray(arguments.data[arguments.fieldName]);
		var compareSet = getParameterValue();

		// we only reckon with sets that have unique values, so the number of elements of both sets is the same
		if (ArrayLen(set) == ArrayLen(compareSet)) {
			result = isSubset(set, compareSet);
		}

		return result
	}

}