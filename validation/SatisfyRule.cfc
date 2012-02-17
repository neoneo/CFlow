component SatisfyRule implements="Rule" {

	public void function init(required string condition) {

		// replace all ColdFusion operators by their script counterparts
		var result = ReplaceList(arguments.condition," eq , lt , lte , gt , gte , neq , not , and , or , mod "," == , < , <= , > , >= , != , ! , && , || , % ");
		// interpret all remaining alphanumeric terms as a field name (which will be available in arguments.data)
		result = REReplaceNoCase(" " & result & " ", " ([a-z_]+[a-z0-9_]*) ", " arguments.data.\1 ", "all");
		// remove excess whitespace
		result = REReplace(Trim(result), "[\s]+", " ", "all");

		variables.condition = result;

	}

	public boolean function test(required struct data) {
		return Evaluate(variables.condition);
	}

}