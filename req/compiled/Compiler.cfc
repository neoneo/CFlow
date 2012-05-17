component Compiler {

	public void function compile(required string mapping) {

		var path = ExpandPath(arguments.mapping);
		var phases = ["start", "end", "before", "after"];
		var hasPhase = {
			start = false,
			end = false,
			before = false,
			after = false
		}
		// variables.tasks is a struct where each key is a target name
		for (var name in variables.tasks) {
			var file = FileOpen(path & "/" & name & ".cfc", "write");
			FileWriteLine("component #name# extends=""cflow.req.compiled.Target"" {");

			FileWriteLine("variables.controller = getContext().getController(""#name#"");");

			var tasks = variables.tasks[name];
			// tasks contains all the tasks for this target, stored by phase and by event
			// first create tasks for all phases
			for (var phase in phases) {
				if (StructKeyExists(tasks, phase) && !ArrayIsEmpty(tasks[phase])) {
					hasPhase[phase] = true;
					FileWriteLine("private void function #phase#(required Event event) {");
					for (var task in tasks[phase]) {
						compileTask(task, file);
					}
					FileWriteLine("}");
				}
			}

			tasks = tasks.events;
			// tasks is now a struct where keys are event types
			for (var type in tasks) {
				FileWriteLine("public void function #type#(required Event event) {");
				if (hasPhase.before) {
					FileWriteLine("before(arguments.event);");
				}
				for (var task in tasks[type]) {
					compileTask(task, file);
				}
				if (hasPhase.after) {
					FileWriteLine("after(arguments.event);");
				}

				FileWriteLine("}");
			}

			FileWriteLine("}");
			FileClose(file);
		}

	}

	private void function compileTask(required struct task, required file file) {



	}

	private void function compileInvokeTask(required struct task, required file file) {

		if (!StructKeyExists(arguments.task, "controller")) {
			Throw(type = "cflow.request", message = "No controller associated with invoke task for method '#arguments.task.method#'");
		}

		var controller = "variables.controller";
		if (arguments.task.controller != defaultController) {
			controller = "getContext().getController(""#arguments.task.controller#"")";
		}
		FileWriteLine(arguments.file, "#controller#.#arguments.task.method#(arguments.event));");
		FileWriteLine("if (arguments.event.isAborted()) return;");
		compileSubtasks(arguments.task, required file file);

	}

	private void function compileDispatchTask(required struct task, required file file) {

		var target = "this";
		if (arguments.task.target != name) {
			target = "getContext().getTarget(""#arguments.task.target#"")";
		}
		FileWriteLine("#target#.#arguments.task.event#(arguments.event);");

	}

	private void function compileRenderTask(required struct task, required file file) {

		var view = arguments.task.view;
		var contentKey = arguments.task.view;
		var mapping = variables.context.getViewMapping();
		if (Len(mapping) > 0) {
			// prepend the given mapping
			view = mapping & "/" & view;
		}

		FileWriteLine("render(""#arguments.task.view#"", arguments.event.getProperties(), arguments.response, ""#contentKey#"");");
	}

	private void function compileRedirectTask(required struct task, required file file) {

		var permanent = StructKeyExists(arguments.task, "permanent") ? arguments.task.permanent : false;

		var parameters = StructCopy(arguments.task);
		StructDelete(parameters, "permanent");
		StructDelete(parameters, "$type");

		// there are two types of redirects: to an event and to a url
		// depending on the type, the constructor expects different parameters
		var type = "event";
		if (StructKeyExists(arguments.task, "url")) {
			// the redirect should be to the url defined here
			type = "url";
		}
		// if there is a parameters attribute present, convert the value to an array
		if (StructKeyExists(parameters, "parameters")) {
			parameters.parameters = ListToArray(parameters.parameters);
		}

		switch (type) {
			case "url":
				// the url key should be present
				var urlString = arguments.parameters.url;
				break;

			case "event":
				variables.urlString = "";

				// the request strategy should be present, target and event keys are optional in parameters
				variables.requestStrategy = arguments.requestStrategy;
				variables.target = StructKeyExists(arguments.parameters, "target") ? arguments.parameters.target : "";
				variables.event = StructKeyExists(arguments.parameters, "event") ? arguments.parameters.event : "";
				break;
		}

		variables.generate = false; // generate the url at runtime?

		// handle runtime parameters if present
		if (StructKeyExists(arguments.parameters, "parameters")) {
			variables.generate = true;
			// this should be an array of parameters to be evaluated at runtime
			// a parameter can be a single name, in which case the parameter name and value are taken from the event as is
			// optionally, they can have the form '<name1>=<name2>', where name1 gives the name of the parameter and name2 gives the value (if it exists on the event)
			// convert them all to the same form
			local.parameters = [];
			for (var parameter in arguments.parameters.parameters) {
				var transport = {};
				if (ListLen(parameter, "=") > 1) {
					transport.name = Trim(ListFirst(parameter, "="));
					transport.value = Trim(ListLast(parameter, "="));
				} else {
					// name and value are the same
					transport.name = Trim(parameter);
					transport.value = Trim(parameter);
				}
				ArrayAppend(local.parameters, transport);
			}
			variables.parameters = local.parameters;
		} else {
			// no runtime parameters
			if (variables.type == "event") {
				// the url is always the same, so we can generate it now
				variables.urlString = arguments.requestStrategy.writeUrl(variables.target, variables.event);
			}
		}

		if (arguments.permanent) {
			variables.statusCode = 301;
		} else {
			variables.statusCode = 302;
		}

	}

	private void function compileIfTask(required struct task, required file file) {
		FileWriteLine("if (#compileExpression(arguments.task.condition)#) {");
		// TODO: in compileSubtasks wordt nu nog er vanuit gegaan dat het event gecanceld is
		compileSubtasks(arguments.task, arguments.file);
		FileWriteLine("}");
	}

	private void function compileElseTask(required struct task, required file file) {

		var command = "else";
		if (StructKeyExists(arguments.task, "condition")) {
			command &= " if (#compileExpression(arguments.task.condition)#)";
		}
		FileWriteLine("} " & command & " {");
		compileSubtasks(arguments.task, arguments.file);

	}

	private void function compileSubtasks(required struct task, required file file) {

		if (StructKeyExists(arguments.task, "sub")) {
			FileWriteLine("if (arguments.event.isCanceled()) {");
			FileWriteLine("arguments.event.reset();");
			for (var subtask in arguments.task.sub) {
				compileTask(subtask, file);
			}
			FileWriteLine("arguments.event.cancel();");
			FileWriteLine("return;");
			FileWriteLine("}");
		}

	}

	private string function compileExpression(required string expression) {

		var result = " " & arguments.expression & " ";
		// replace ColdFusion operators by their script counterparts
		result = ReplaceList(result, " eq , lt , lte , gt , gte , neq , not , and , or , mod ", " == , < , <= , > , >= , != , !, && , || , % ");
		// interpret remaining alphanumeric terms without a parenthesis as a field name (which will be available in arguments.data)
		// explanation:
		// before the variable name there must be a space, or one of ( , + - * / & ^ = < > ! | %
		// the variable name must be followed by one of those characters, except (, and including . )
		return REReplaceNoCase(result, "([ (,+*/&^=<>!|%-])([a-z_]+[a-z0-9_]*)([ )\.,+*/&^=<>!|%-])", "\1arguments.event.\2\3", "all");
	}

}