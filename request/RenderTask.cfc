component RenderTask implements="Task" {

	public void function init(required Renderer renderer, required string template) {
		variables.renderer = arguments.renderer;
		variables.template = arguments.template;
	}

	public boolean function process(required Event event, required Response response) {
		variables.renderer.render(template, arguments.event.getProperties(), arguments.response);

		return true;
	}

}