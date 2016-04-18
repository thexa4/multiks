//object.ks

global type to lexicon().

function object_construct_type { 
	parameter typename.
	
	local typedef to type[typename].
	// Create prototype
	local result to typedef["prototype"]:copy.
	
	// Bind functions to created object
	for key in result:keys {
		if result[key]:isType("Delegate") {
			set result[key] to result[key]:bind(result).
		} else if (result[key]:isType("List") or result[key]:isType("Lexicon")) {
			set result[key] to result[key]:copy.
		}
	}
	
	return result.
}

function object_inherit {
	parameter typename, super, methods.
	
	local superdef to type[super].
	local result to lexicon(
		"type", typename,
		"super", super,
		"prototype", superdef["prototype"]:copy
	).
	
	// Append or overwrite functions and variables
	for key in methods:keys {
		set result["prototype"][key] to methods[key].
	}
	
	// Set default constructor
	set result["new"] to object_construct_type@:bind(typename).
	
	// Set type name
	set result["prototype"]["type"] to typename.
	
	set type[typename] to result.
	return result.
}

function object_copy {
	parameter this.
	
	local result to this:copy.
	local prototype to type[result["class"]]["prototype"].
	// Rebind functions to created object, adding functions after creation is not supported!
	for key in prototype:keys {
		if result[key]:isType("Delegate") {
			set result[key] to prototype[key]:bind(result).
		} else if (result[key]:isType("List") or result[key]:isType("Lexicon")) {
			set result[key] to result[key]:copy.
		}
	}
	
	return result.
}

function object__toString { parameter this. return "object". }

global object to lexicon(
	"type", "object",
	"abstract", true,
	"prototype", lexicon("copy", object_copy@, "toString", object__toString@)).

set object["new"] to object_construct_type@:bind(object).
set type["object"] to object.
