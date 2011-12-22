component View {

	public void function render(required string template, required struct properties, required Response response) {

		var template = arguments.template;
		var properties = arguments.properties;
		var response = arguments.response;

		savecontent variable="content" {
			include arguments.template & ".cfm";
		}

		response.write(content);
	}

}