component RenderTask implements="Task" {

	public void function init(required Renderer renderer, required string template) {
		variables.renderer = arguments.renderer;
		variables.template = arguments.template;
	}

	public boolean function process(required Event event) {
		variables.renderer.render(template, arguments.event.getProperties(), arguments.event.getResponse());

		return true;
	}

}