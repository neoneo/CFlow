component AbortTask implements="Task" {

	public boolean function run(required Event event) {

		arguments.event.cancel();

		return true;
	}

	public string function getType() {
		return "cancel";
	}

}