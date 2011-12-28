component Response {

	public void function init() {
		variables.type = "HTML";
		variables.contentTypes = {
			HTML = "text/html",
			JSON = "application/json",
			TEXT = "text/plain"
		};
		variables.contents = [];
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

	public void function write(required any content) {
		ArrayAppend(variables.contents, arguments.content);
	}

	public array function getContents() {
		return variables.contents;
	}

	/**
	 * Default implementation for rendering HTML and JSON.
	 **/
	public string function render() {

		var result = "";
		var contents = getContents();

		switch (getType()) {
			case "HTML":
			case "TEXT":
				for (var content in contents) {
					if (IsSimpleValue(content)) {
						result &= content;
					}
				}
				break;
			case "JSON":
				// if there is 1 element in the content, serialize that
				// if there are more, serialize the whole array
				if (ArrayLen(contents) == 1) {
					result = SerializeJSON(contents[1]);
				} else {
					result = SerializeJSON(contents);
				}
				break;
		}

		//clear();

		return result;
	}

	public void function clear() {
		ArrayClear(variables.contents);
	}

	public array function getExecutedTasks() {
		return variables.executedTasks;
	}

	package void function addExecutedTask(required string targetName, required string eventType, struct task = JavaCast("null", 0)) {
		if (!StructKeyExists(variables, "executedTasks")) {
			variables.executedTasks = [];
		}
		ArrayAppend(variables.executedTasks, {
			target = arguments.targetName,
			event = arguments.eventType,
			task = arguments.task
		});
	}


}