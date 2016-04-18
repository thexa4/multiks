run once task.
run once os.

global service to service_define("service", "object", lexicon(), lexicon(), service__idle@:bind(false)).

function service_define {
	parameter typename, super, methods, concurrent, service.
	
	set concurrent["_step"] to list(service__call_step@, 0).
	set methods["_schedule"] to service__init@.
	set methods["_returnError"] to service__error@.
	set methods["_returnResult"] to service__result@.
	set methods["_cleanup"] to service__idle@.
	set methods["_running"] to false.
	set methods["_servicePriority"] to os_lock_default.
	set methods["_suspendFor"] to service__suspend_for@.
	set methods["step"] to service.
	
	return object_concurrent(typename, super, methods, concurrent).
}

function service__init {
	parameter this, description.
	
	if this["_running"] {
		local result to task["dummy"](description).
		result["setError"]("Already running").
		return result.
	}
	
	set description to this["type"] + " service [" + description + "]".
	set this["_serviceDescription"] to description.
	
	local result to task["fromFunc"](service__start@:bind(description):bind(this), description).
	set this["_task"] to result.
	return result.
}

function service__call_step {
	parameter this.
	this["step"]().
}

function service__idle {
	parameter this.
}

function service__start {
	parameter description, this, runtask.
	
	if this["_running"] {
		local result to task["dummy"](description).
		result["setError"]("Already running").
		return result.
	}
	
	set this["_running"] to true.
	
	if(not task__setup(runtask)) {
		print "Service init failure in " + description.
		exit.
	}
	
	os["instance"]["schedule"](this["_step"], description, this["_servicePriority"]).
	return.
}

function service__error {
	parameter this, error.
	
	if this["_task"]["status"] <> "RUNNING" {
		print "Error: service stop without start".
		return false.
	}
	
	this["_task"]["setError"](error).
	
	os["instance"]["unschedule"](this["_serviceDescription"]).
	this["_cleanup"]().
	set this["_running"] to false.
	
	return true.
}

function service__result {
	parameter this, result.
	
	if this["_task"]["status"] <> "RUNNING" {
		print "Error: service stop without start".
		return false.
	}
	
	this["_task"]["setResult"](result).
	
	os["instance"]["unschedule"](this["_serviceDescription"]).
	this["_cleanup"]().
	set this["_running"] to false.
	
	return true.
}

function service__suspend_for {
	parameter this, waitTask.
	
	os["instance"]["unschedule"](this["_serviceDescription"]).
	waitTask["continueWith"](task["create"](service__resume@:bind(this), "resume service")).
}

function service__resume {
	parameter this.
	
	os["instance"]["schedule"](this["_step"], description, this["_servicePriority"]).
}