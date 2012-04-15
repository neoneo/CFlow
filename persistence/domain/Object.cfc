/**
 * The root domain object that all domain objects extend.
 **/
component Object {

	include "../static/invoke.cfm";

	variables._ = {
		persisted = false,
		modified = false,
		loaded = false,
		populated = false,
		identifier = CreateUniqueId() // Railo specific function
	};

	public boolean function isPersisted() {
		return variables._.persisted;
	}

	public boolean function isModified() {
		return variables._.modified;
	}

	public void function configure(required struct descriptor, required Factory factory) {
		variables._.descriptor = arguments.descriptor;
		variables._.factory = arguments.factory;
		variables._.entity = variables._.factory.getEntity(variables._.descriptor.entity);
	}

	public void function populate(required struct data) {

		// data should have keys that map to property names


		// the first call to this method does not make the object dirty unless it is a new object
		variables._.modified = variables._.populated || !variables._.persisted;
		variables._.populated = true;
		variables._.persisted = StructKeyExists(variables, variables._.descriptor.key);

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

		// check if the call must be directed to a decorated object
		if (StructKeyExists(descriptor, "decorates")) {
			// descriptor.decorates is the name of the property that contains the object
			instance = getProperty(descriptor.decorates.entity);
			methodName = descriptor.decorates.method;
		}

		// all accessor methods require a property name; the setters additionally require a value (1 argument) (which can be null however)
		return ArrayIsDefined(arguments.missingMethodArguments, 1) ? invokeMethod(instance, methodName, arguments.missingMethodArguments[1]) : invokeMethod(instance, methodName);
	}

	public boolean function equals(required any instance) {
		// we assume that there is ever only one instance for a given record in the current session
		return arguments.instance.identifierEquals(variables._.identifier);
	}

	public boolean function identifierEquals(required string identifier) {
		return variables._.identifier == arguments.identifier;
	}

	private any function getProperty(required string name) {

		if (!variables._.loaded && variables._.persisted) {
			var result = variables._.entity.readById(variables[variables._.descriptor.key]);
			// result is a struct where keys are property names
			for (var key in result) {
				// the value could be null
				if (StructKeyExists(result, key)) {
					setProperty(key, result[key]);
				} else {
					setProperty(key);
				}
			}
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
					variables._modified = !variables[arguments.name].equals(arguments.value);
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

	private void function setCollection(required string name, required any collection) {

	}

	private void function addToCollection(required string name, required any member) {

		var collection = getCollection(arguments.name);
		if (!collection.hasMember(arguments.member)) {
			collection.add(arguments.member);
			// also set the relation on the other side
			var property = variables._.descriptor.properties[arguments.name];
			invokeMethod(arguments.member, "set#property.relation#", {value = this});
		}

	}

	private void function removeFromCollection(required string name, required any member) {

		var collection = getCollection(arguments.name);
		if (collection.hasMember(arguments.member)) {
			collection.remove(arguments.member);
			var property = variables._.descriptor.properties[arguments.name];
			invokeMethod(arguments.member, "set#property.relation#", {value = JavaCast("null", 0)});
		}

	}

	private boolean function hasCollectionMember(required string name, any member) {

		var collection = getCollection(arguments.name);
		if (StructKeyExists(arguments, "member")) {
			return collection.hasMember(arguments.member);
		} else {
			return !collection.isEmpty();
		}
	}

}