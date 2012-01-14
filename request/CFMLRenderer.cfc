component CFMLRenderer implements="Renderer" {

	public void function render(required string template, required struct properties, required Response response) {

		// create the following variables for use within the template
		var template = arguments.template;
		var properties = arguments.properties;
		var response = arguments.response;

		savecontent variable="local.content" {
			include arguments.template & ".cfm";
		}

		response.write(content);

	}

}