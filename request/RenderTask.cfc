component RenderTask implements="Task" {

	public void function init(required string template) {

		variables.template = arguments.template;

	}

	public boolean function run(required Event event) {

		// create the following variables for use within the template
		var template = variables.template;
		var properties = arguments.event.getProperties();
		var response = arguments.event.getResponse();

		savecontent variable="local.content" {
			include variables.template & ".cfm";
		}

		response.write(content);

		return true;
	}

}