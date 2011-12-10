component {

	variables.response = {};

	public void function init(required Context context) {
		variables.context = arguments.context;
		variables.factory = variables.context.getFactory();
	}

	/**
	 * Processes the tasks using the event.
	 **/
	public boolean function processTasks(required array tasks, required Event event) {

		for (var task in arguments.tasks) {
			executeTask(task, arguments.event);
			if (arguments.event.isCancelled()) {
				break;
			}
		}

		return !arguments.event.isCancelled();
	}

	public struct function getResponse() {
		return variables.response;
	}

	public void function clearResponse(string view) {

		if (!IsNull(arguments.view)) {
			StructDelete(variables.response, arguments.view);
		} else {
			StructClear(variables.response);
		}
	}

	/**
	 * Executes the given task using the given event.
	 **/
	private void function executeTask(required struct task, required Event event) {

		// a task can be one of the following:
		// invoke: invoke the event handler of that name
		// view: render the view of that name
		// dispatch: dispatch the event of that name
		if (StructKeyExists(arguments.task, "invoke") {
			// invoke the given event handler
			var handler = JavaCast("null", 0);
			var method = "";
			if (ListLen(arguments.task.invoke, ".") == 1) {
				// no explicit handler specified, so use the event target
				handler = arguments.event.getTarget();
				method = arguments.task.invoke;
			} else {
				handler = variables.factory.createHandler(ListFirst(arguments.task.invoke, "."));
				method = ListLast(arguments.task.invoke);
			}
			// invoke the handler method
			handler[method](arguments.event);
			if (arguments.event.isCancelled()) {
				// if there is an instead key in the task, execute it
				if (StructKeyExists(arguments.task, "instead") {
					executeTask(arguments.task.instead, arguments.event);
				}
			}
		} else if (StructKeyExists(arguments.task, "render")) {
			var view = arguments.task.view;
			if (ListLen(arguments.task.view, ".") == 1) {
				view = targetName & "." & view;
			}

			variables.response[view] = variables.factory.createView(view).render(arguments.event.getProperties());
		} else if (StructKeyExists(arguments.task, "dispatch") {
			// dispatch the given event
			var properties = arguments.event.getProperties();
			var success = false;
			// if the event is a single list item, dispatch it on the event target, otherwise create a node instance to dispatch it on
			if (ListLen(arguments.task.dispatch, ".") == 1) {
				success = arguments.event.getTarget().dispatchEvent(arguments.task.dispatch, properties);
			} else {
				var handler = variables.factory.createHandler(ListFirst(arguments.task.dispatch, "."));
				success = handler.dispatchEvent(ListLast(arguments.task.dispatch, "."), properties);
			}
			if (!success) {
				arguments.event.cancel();
				// if there is an instead key in the task, execute it
				if (StructKeyExists(arguments.task, "instead") {
					executeTask(arguments.task.instead, arguments.event);
				}
			}
		} else {
			throw (type = "cflow", message = "Illegal definition for event #targetName#.#arguments.event.getType()#");
		}

	}

}