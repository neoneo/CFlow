/**
 * The root domain object that all domain objects extend.
 **/
component Object {

	variables._ = {
		persisted = false,
		modified = false,
		loaded = false,
		populated = false
	};

	public boolean function isPersisted() {
		return variables._.persisted;
	}

	public boolean function isModified() {
		return variables._.modified;
	}

	public void function init(required struct descriptor, required Context context) {
		variables._.descriptor = arguments.descriptor;
		variables._.context = arguments.context;
		variables._.entity = variables._.context.getEntity(variables._.descriptor.entity);
	}

	public void function populate(required struct data) {

		if (!variables._.populated) {
			// set the modified flag to true, to prohibit equality checks in setProperty()
			variables._.modified = true;
		}

		// data should have keys that map to property names
		for (var key in arguments.data) {
			// the value could be null
			if (StructKeyExists(arguments.data, key)) {
				setProperty(key, arguments.data[key]);
			} else {
				setProperty(key);
			}
		}

		// the first call to this method does not make the object dirty unless it is a new object
		if (!variables._.populated) {
			variables._.persisted = StructKeyExists(variables, variables._.descriptor.key);
			variables._.modified = !variables._.persisted && !StructIsEmpty(arguments.data);
			variables._.populated = true;
		}

	}

	public struct function extract() {

	}

	public any function onMissingMethod(required string missingMethodName, required array missingMethodArguments) {

		if (!StructKeyExists(variables._.descriptor.methods, arguments.missingMethodName) {
			Throw(type = "cflow.persistence", "Unknown method '#arguments.missingMethodName#'");
		}

		// determine the method to invoke
		var descriptor = variables._.descriptor.methods[arguments.missingMethodName];
		var instance = this;
		var methodName = descriptor.name;
		var propertyName = descriptor.property;

		// check if the call must be directed to a decorated object
		if (StructKeyExists(descriptor, "decorates")) {
			instance = getProperty(descriptor.decorates.entity);
			methodName = descriptor.decorates.method;
		}

		// all accessor methods require a property name; the setters additionally require a value (1 argument) (which can be null however)
		var parameters = {name = propertyName};
		if (ArrayIsDefined(arguments.missingMethodArguments, 1)) {
			parameters.value = arguments.missingMethodArguments[1];
		}
		return invokeMethod(instance, methodName, parameters);
	}

	private any function getProperty(required string name) {

		if (!variables._.loaded && variables._.persisted) {
			var result = variables._.entity.readById(variables[variables._.descriptor.key]);
			// result is a struct where keys are property names
			populate(result);
			variables._.loaded = true;
		}

		if (StructKeyExists(variables, arguments.name)) {
			return variables[arguments.name];
		}
	}

	private void function setProperty(required string name, required any value) {

		var valueExists = StructKeyExists(arguments.value);
		if (!variables._.modified) {
			var propertyExists = StructKeyExists(variables, arguments.name);
			if (propertyExists && valueExists) {
				// check for equality, assuming the value has the correct type
				var property = variables._.descriptor.properties[arguments.name];
				if (property.fieldtype == "column") {
					variables._.modified = variables[arguments.name] != arguments.value;
				} else {
					// check for object equality
					variables._.modified = !ObjectEquals(variables[arguments.name], arguments.value);
				}
			} else {
				// the object is modified if one is null and the other is not
				variables._.modified = propertyExists == !valueExists;
			}
		}

		variables[arguments.name] = valueExists ? arguments.value : JavaCast("null", 0);

	}

	private Collection function getCollection(required string name) {

		if (!StructKeyExists(variables, arguments.name)) {
			var property = variables._.descriptor.properties[arguments.name];
			// create a collection for the entity
			variables[arguments.name] = variables._.factory.createCollection(property.entity, {"#property.relation#" = this});
		}

		return variables[arguments.name];
	}

	private void function setCollection(required string name, required any value) {

	}

	private void function addToCollection(required string name, required any value) {

		var collection = getCollection(arguments.name);
		if (!collection.hasMember(arguments.value)) {
			collection.add(arguments.value);
			// also set the relation on the other side
			var property = variables._.descriptor.properties[arguments.name];
			invokeMethod(arguments.value, "set#property.relation#", {value = this});
		}

	}

	private void function removeFromCollection(required string name, required any value) {

		var collection = getCollection(arguments.name);
		if (collection.hasMember(arguments.value)) {
			collection.remove(arguments.value);
			var property = variables._.descriptor.properties[arguments.name];
			invokeMethod(arguments.value, "set#property.relation#", {value = JavaCast("null", 0)});
		}

	}

	private Object function createCollectionMember(required string name) {

	}

	private boolean function hasCollectionMember(required string name, any value) {

		var collection = getCollection(arguments.name);
		if (StructKeyExists(arguments, "value")) {
			return collection.hasMember(arguments.value);
		} else {
			return !collection.isEmpty();
		}
	}

}