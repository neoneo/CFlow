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
			FileWriteLine(file, "component #name# extends=""cflow.req.compiled.Target"" {");

			FileWriteLine(file, "variables.controller = getContext().getController(""#name#"");");

			var tasks = variables.tasks[name];
			// tasks contains all the tasks for this target, stored by phase and by event
			// first create tasks for all phases
			for (var phase in phases) {
				if (StructKeyExists(tasks, phase) && !ArrayIsEmpty(tasks[phase])) {
					hasPhase[phase] = true;
					FileWriteLine(file, "private void function #phase#(required Event event) {");
					for (var task in tasks[phase]) {
						compileTask(task, file);
					}
					FileWriteLine(file, "}");
				}
			}

			tasks = tasks.events;
			// tasks is now a struct where keys are event types
			for (var type in tasks) {
				FileWriteLine(file, "public void function #type#(required Event event) {");
				if (hasPhase.before) {
					FileWriteLine(file, "before(arguments.event);");
				}
				for (var task in tasks[type]) {
					compileTask(task, file);
				}
				if (hasPhase.after) {
					FileWriteLine(file, "after(arguments.event);");
				}

				FileWriteLine(file, "}");
			}

			FileWriteLine(file, "}");
			FileClose(file);
		}

	}

	private void function compileTask(required struct task, required file file) {
		invokeMethod(this, "compile" & arguments.task.$type & "Task", arguments);
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
		FileWriteLine(file, "if (arguments.event.isAborted()) return;");
		compileSubtasks(arguments.task, required file file);

	}

	private void function compileDispatchTask(required struct task, required file file) {

		var target = "this";
		if (arguments.task.target != name) {
			target = "getContext().getTarget(""#arguments.task.target#"")";
		}
		FileWriteLine(file, "#target#.#arguments.task.event#(arguments.event);");

	}

	private void function compileRenderTask(required struct task, required file file) {

		var view = arguments.task.view;
		var contentKey = arguments.task.view;
		var mapping = variables.context.getViewMapping();
		if (Len(mapping) > 0) {
			// prepend the given mapping
			view = mapping & "/" & view;
		}

		FileWriteLine(file, "render(""#arguments.task.view#"", arguments.event.getProperties(), arguments.response, ""#contentKey#"");");
	}

	private void function compileRedirectTask(required struct task, required file file) {

		var permanent = StructKeyExists(arguments.task, "permanent") ? arguments.task.permanent : false;

		var parameters = StructCopy(arguments.task);
		StructDelete(parameters, "permanent");
		StructDelete(parameters, "$type");
		StructDelete(parameters, "url");
		StructDelete(parameters, "target");
		StructDelete(parameters, "event");

		// handle runtime parameters if present
		if (!StructIsEmpty(parameters)) {
			for (var name in parameters) {
				parameters[name] = compileExpression(parameters[name]);
			}
		}

		// there are two types of redirects: to an event and to a url
		var type = "event";
		if (StructKeyExists(arguments.task, "url")) {
			// the redirect should be to the url defined here
			type = "url";
		}

		switch (type) {
			case "url":
				// the url key should be present
				FileWriteLine(file, "var urlString = #compileExpression(arguments.task.url)#;");
				if (!StructIsEmpty(parameters)) {
					FileWriteLine(file, "if (urlString does not contain ""?"") urlString &= ""?"";");
					FileWriteLine(file, "var queryString = """"");
					for (var name in parameters) {
						FileWriteLine(file, "queryString = ListAppend(queryString, #name# = UrlEncodedFormat(#parameters[name]#), ""&"");");
					}
					FileWriteLine(file, "urlString &= queryString");
				}
				break;

			case "event":
				var target = StructKeyExists(arguments.task, "target") ? compileExpression(arguments.task.target) : "";
				var event = StructKeyExists(arguments.task, "event") ? compileExpression(arguments.task.event) : "";
				FileWriteLine(file, "var targetName = #target#;");
				FileWriteLine(file, "var eventType = #event#;");
				FileWriteLine(file, "var parameters = {};");
				for (var name in parameters) {
					FileWriteLine(file, "parameters[""#name#""] = #parameters[name]#;");
				}
				FileWriteLine(file, "var urlString = variables.requestStrategy.writeUrl(targetName, eventType, parameters);");
				break;
		}

		var statusCode = permanent ? 301 : 302;

		FileWriteLine(file, "Location(urlString, false, #statusCode#);");

	}

	private void function compileIfTask(required struct task, required file file) {
		FileWriteLine(file, "if (#compileExpression(arguments.task.condition)#) {");
		for (var subtask in arguments.task.sub) {
			compileTask(subtask, file);
		}
		FileWriteLine(file, "}");
	}

	private void function compileElseTask(required struct task, required file file) {

		var command = "else";
		if (StructKeyExists(arguments.task, "condition")) {
			command &= " if (#compileExpression(arguments.task.condition)#)";
		}
		FileWriteLine(file, "} " & command & " {");
		compileSubtasks(arguments.task, arguments.file);

	}

	private void function compileSetTask(required struct task, required file file) {

		var attributes = StructCopy(arguments.task);
		var overwrite = !StructKeyExists(arguments.task, "overwrite") || arguments.task.overwrite;
		StructDelete(attributes, "$type");
		StructDelete(attributes, "overwrite");
		var name = ListFirst(StructKeyList(attributes));
		var expression = compileExpression(arguments.task[name]);

		if (!overwrite) {
			FileWriteLine(file, "if (!StructKeyExists(arguments.event, ""#name#"")) {");
		}
		FileWriteLine(file, "arguments.event.#name# = #expression#");
		if (!overwrite) {
			FileWriteLine(file, "}");
		}

	}

	private void function compileSubtasks(required struct task, required file file) {

		if (StructKeyExists(arguments.task, "sub")) {
			FileWriteLine(file, "if (arguments.event.isCanceled()) {");
			FileWriteLine(file, "arguments.event.reset();");
			for (var subtask in arguments.task.sub) {
				compileTask(subtask, file);
			}
			FileWriteLine(file, "arguments.event.cancel();");
			FileWriteLine(file, "return;");
			FileWriteLine(file, "}");
		}

	}

	private string function compileExpression(required string expression) {

		local.expression = arguments.expression;
		var parse = false;
		if (Left(arguments.expression, 1) == "%") {
			parse = true;
			local.expression = RemoveChars(local.expression, 1, 1);
			// if another % follows, the first one should be interpreted as an escape character
			if (Left(local.expression, 1) == "%") {
				parse = false;
			}
		}

		var result = local.expression;
		if (parse) {
			result = " " & result & " ";
			// replace ColdFusion operators by their script counterparts
			result = ReplaceList(result, " eq , lt , lte , gt , gte , neq , not , and , or , mod ", " == , < , <= , > , >= , != , !, && , || , % ");
			// interpret remaining alphanumeric terms without a parenthesis as a field name (which will be available in arguments.data)
			// explanation:
			// before the variable name there must be a space, or one of ( , + - * / & ^ = < > ! | %
			// the variable name must be followed by one of those characters, except (, and including . )
			result = REReplaceNoCase(result, "([ (,+*/&^=<>!|%-])([a-z_]+[a-z0-9_]*)([ )\.,+*/&^=<>!|%-])", "\1arguments.event.\2\3", "all");
			result = Trim(result);
		} else {
			result = """" & Replace(local.expression, """", """""", "all") & """";
		}

		return result;
	}

}