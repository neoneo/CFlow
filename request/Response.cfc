component {

	variables.type = "HTML";
	variables.contentTypes = {
		HTML = "text/html",
		JSON = "application/json",
		TEXT = "text/plain"
	};

	public void function init() {
		variables.content = {}; // store content by view name
		variables.viewNames = []; // keep the order in which views write content
	}

	public void function setType(required string type) {
		variables.type = arguments.type;
	}

	public string function getType() {
		return variables.type;
	}

	public string function getContentType() {
		return variables.contentTypes[getType()];
	}

	public void function write(required string viewName, required any content) {
		if (!StructKeyExists(variables.content, arguments.viewName)) {
			ArrayAppend(variables.viewNames, arguments.viewName);
		}
		variables.content[arguments.viewName] = arguments.content;
	}

	public array function getRawContent() {

		var rawContent = [];
		for (var viewName in variables.viewNames) {
			ArrayAppend(rawContent, variables.content[viewName]);
		}

		return rawContent;
	}

	/**
	 * Default implementation for rendering HTML and JSON.
	 * Override this method, or use getRawContent(), to render other content types or to render differently.
	 **/
	public string function render() {

		var rawContent = getRawContent();
		var result = "";

		switch (getContentType()) {
			case "HTML":
			case "TEXT":
				for (var content in rawContent) {
					if (IsSimpleValue(content)) {
						result &= content;
					}
				}
				break;
			case "JSON":
				// if there is 1 element in the raw content, serialize that
				// if there are more, serialize the whole array
				if (ArrayLen(rawContent) == 1) {
					result = SerializeJSON(rawContent[1]);
				} else {
					result = SerializeJSON(rawContent);
				}
				break;
		}

		return result;
	}

	public void function clear(string viewName) {
		if (StructKeyExists(arguments, "viewName")) {
			var index = ArrayFind(variables.viewNames, arguments.viewName);
			if (index > 0) {
				StructDelete(variables.content, arguments.viewName);
				ArrayDeleteAt(variables.viewNames, index);
			}
		} else {
			StructClear(variables.content);
			ArrayClear(variables.viewNames);
		}
	}

}