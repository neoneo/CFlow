component {

	public Any function walk(required Builder builder, required XML element) {

		var builder = arguments.builder
		var products = ArrayMap(arguments.element.xmlChildren, function (element) {
			return walk(builder, arguments.element)
		})

		return build(arguments.builder, arguments.element, products)
	}

	private Any function build(required Builder builder, required XML element, required Array products) {
		return arguments.builder["build" & arguments.element.xmlName](arguments.element, arguments.products)
	}

}