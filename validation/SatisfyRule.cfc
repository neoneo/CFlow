component SatisfyRule implements="Rule" {

	public void function init(required string condition) {

		// replace all ColdFusion operators by their script counterparts
		var result = ReplaceList(arguments.condition," eq , lt , lte , gt , gte , neq , not , and , or , mod "," == , < , <= , > , >= , != , ! , && , || , % ");
		// add spaces between parentheses so it's easy to discriminate between variables and function names or arguments
		result = ReplaceList(result, "(,)", "( , )");
		result = Replace(result, ",", " , ", "all"); // surround commas with spaces too
		// interpret remaining alphanumeric terms without a parenthesis as a field name (which will be available in arguments.data)
		result = REReplaceNoCase(" " & result & " ", " ([a-z_]+[a-z0-9_]*)(?!\() ", " arguments.data.\1 ", "all");
		// remove excess whitespace
		result = REReplace(Trim(result), "[\s]+", " ", "all");

		variables.condition = result;

	}

	public boolean function test(required struct data) {
		return Evaluate(variables.condition);
	}

}