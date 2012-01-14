component EventTask extends="AbstractTask" {

	public boolean function process(required Event event, required Response response) {
		return processSubtasks(arguments.event, arguments.response);
	}

}