import cflow.task.*;

component implements="Builder" {

	public Task function buildAbort() {
		return new AbortTask()
	}

	public Any function buildCancel() {
		return new CancelTask()
	}

	public Any function buildDispatch() {

	}



	public Any function buildElse();
	public Any function buildEnd();
	public Any function buildEvent();
	public Any function buildIf();

}