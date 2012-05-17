component ComponentReader {

	public void function init(required Context context) {
		variables.context = arguments.context;
	}

	public void function read(required string mapping) {

		var path = "/" & Replace(arguments.mapping, ".", "/", "all");
		var absolutePath = ExpandPath(path);
		var list = DirectoryList(absolutePath, true, "name", "*.cfc");

		for (var name in list) {
			readComponent(arguments.mapping & "." & ListFirst(name, "."));
		}

	}

	public void function readComponent(required string mapping) {

		var metadata = GetComponentMetaData(arguments.mapping);

		if (metadata.type == "component") {
			var name = metadata.name;
			var properties = [];

			for (var property in metadata.properties) {
				ArrayAppend(properties, property);
			}

			while (StructKeyExists(metadata, "extends")) {
				metadata = metadata.extends;
				for (var property in metadata.properties) {
					ArrayAppend(properties, property);
				}
			}

			variables.descriptors[name] = createDescriptor(properties);
		}

	}

	public struct function createDescriptor(required array properties) {

		var descriptor = {};
		for (var property in arguments.properties) {

		}


	}

}