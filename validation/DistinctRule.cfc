/**
 * Checks whether all elements in the set are different.
 **/
component DistinctRule extends="Rule" {

	public void function init(boolean caseSensitive = false) {
		variables.caseSensitive = arguments.caseSensitive;
	}

	public boolean function test(required struct data) {

		var result = true;
		var set = toArray(getValue(arguments.data));
		var count = ArrayLen(set);

		var i = 1;
		while (result && i <= count - 1) {
			var j = i + 1;
			while (result && j <= count) {
				if (variables.caseSensitive) {
					result = Compare(ToString(set[i]), ToString(set[j])) != 0;
				} else {
					result = CompareNoCase(ToString(set[i]), ToString(set[j])) != 0;
				}
				j++;
			}
			i++;
		}

		return result;
	}

}