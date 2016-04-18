run once multithread.

run once object.
global task to object_inherit("task", "object", lexicon(
	"type", "task",
	"status", "CREATED",
	"func", task__run_empty@,
	"result", false,
	"error", false,
	"continuations", list(),
	"description", "Uninitialized task",
	"start", task_start@,
	"setError", task_set_error@,
	"setResult", task_set_result@,
	"continueWith", task_continue_with@,
	"startConcurrent", task_run_concurrent@
)).

set task["create"] to task_init_normal@.
set task["fromFunc"] to task_init_custom@.
set task["dummy"] to task_init_dummy@.
set task["fromResult"] to task_from_result@.
set task["wrapMultiple"] to task__wrap_multiple@.

//Statuses:
// - CREATED
// - CANCELED
// - FAULTED
// - RANTOCOMPLETION
// - RUNNING
// - WAITINGTORUN

function start {
	parameter this.
	
	this["start"]().
	return this.
}

// create
function task_init_normal {
	parameter startfunc, description.
	
	local result to task["new"]().
	set result["func"] to task__run_normal@:bind(startfunc).
	set result["description"] to description.
	
	return result.
}

// fromFunc
function task_init_custom {
	parameter startfunc, description.
	
	local result to task["new"]().
	set result["func"] to startfunc.
	set result["description"] to description.
	
	return result.
}

// dummy
function task_init_dummy {
	parameter description.
	
	local result to task["new"]().
	set result["description"] to description.
	set result["status"] to "RUNNING".
	
	return result.
}

function task__run_empty { parameter this, runtask. task__setup(runtask). print "empty". task__cleanup(runtask, true, list()). }

// setError
function task_set_error {
	parameter this, new_error.
	
	//print "set error for " + this["description"] + " to " + new_error.
	
	if this["status"] <> "RUNNING" {
		global error to list("Task in wrong state to set error", this).
	} else {
		set this["status"] to "FAULTED".
		set this["error"] to new_error.
		
		for cont in this["continuations"] {
			//print "Continuing " + this["description"] + " with: " + cont["description"].
			cont["start"]().
		}
	}
}

// setResult
function task_set_result {
	parameter this, new_result.
	
	//print "set " + this["description"] + " to " + new_result.
	
	if this["status"] <> "RUNNING" {
		global error to list("Task in wrong state to set result", this).
	} else {
		set this["status"] to "RANTOCOMPLETION".
		set this["result"] to new_result.
		
		for cont in this["continuations"] {
			//print "Continuing " + this["description"] + " with: " + cont["description"].
			cont["start"]().
		}
	}
}

function task_continue_with {
	parameter this, continuation.
	
	//print "run " + continuation["description"] + " after " + this["description"].
	
	this["continuations"]:add(continuation).
	
	if this["status"] = "RANTOCOMPLETION" or this["status"] = "FAULTED" {
		continuation["start"]().
	}
	
	return continuation.
}

function task_start {
	parameter this.
	
	if this["status"] <> "CREATED" {
		global error to list("Task in wrong state for start: " + this["status"], this).
		return false.
	}
	
	set this["status"] to "WAITINGTORUN".
	
	local del to task_run_concurrent@.
	local del to del:bind(this).
	
	multithread["instance"]["run"](del, this["description"]).
}

function task__setup {
	parameter this.
	
	if this["status"] <> "WAITINGTORUN" {
		global error to list("Task in wrong state for setup: " + this["status"], this).
		return false.
	}
	
	set this["status"] to "RUNNING".
	global error to list().
	return true.
}

function task_from_result {
	parameter result.
	
	local dummy to task["dummy"]("result").
	
	dummy["setResult"](result).
	return dummy.
}

function task__run_normal {
	parameter delegate, tgt.
	
	if not task__setup(tgt) {
		return false.
	}
	
	local result to delegate:call().
	
	return task__cleanup(tgt, result, list()). // TODO: Fix error passing
}

function task__cleanup {
	parameter this, result, new_error.
	
	if new_error:length > 0 {
		this["setError"](new_error).
	} else {
		this["setResult"](result).
	}
	
	return true.
}

function task_run_concurrent {
	parameter this.
	
	if this["status"] <> "WAITINGTORUN" {
		return.
	}
	
	local startfunc to this["func"].
	local startfunc to startfunc:bind(this).
	return startfunc:call().
}

function task__wrap_multiple {
	parameter first, last, description.
	
	return task["fromFunc"](task__wrap_multiple_start@:bind(first):bind(last), description).
}

function task__wrap_multiple_start {
	parameter starttask, endtask, runtask.
	task__setup(runtask).
	start(starttask).
	// Todo, add error forwarding etc.
	endtask["continueWith"](task["create"](task__wrap_multiple_end@:bind(runtask), "end wrap")).
}

function task__wrap_multiple_end {
	parameter this.
	this["setResult"](true).
}

function task__encapsulate_method_0 {
	parameter description, method, this.
	local del to method:bind(this).
	return task["create"](del, description).
}
function task__encapsulate_method_1 {
	parameter description, method, this, a1.
	local del to method:bind(this):bind(a1).
	return task["create"](del, description).
}
function task__encapsulate_method_2 {
	parameter description, method, this, a1, a2.
	local del to method:bind(this):bind(a1):bind(a2).
	return task["create"](del, description).
}
function task__encapsulate_method_3 {
	parameter description, method, this, a1, a2, a3.
	local del to method:bind(this):bind(a1):bind(a2):bind(a3).
	return task["create"](del, description).
}
function task__encapsulate_method_4 {
	parameter description, method, this, a1, a2, a3, a4.
	local del to method:bind(this):bind(a1):bind(a2):bind(a3):bind(a4).
	return task["create"](del, description).
}


function object_concurrent {
	parameter typename, super, methods, concurrent.
	
	local result to object_inherit(typename, super, methods).
	
	// Bind concurrent methods
	for key in concurrent:keys {
		print key.
		local argsize to concurrent[key][1].
		local encap to "unencapsulated".
		
		if argsize = 0 { set encap to task__encapsulate_method_0@. }
		else if argsize = 1 { set encap to task__encapsulate_method_1@. }
		else if argsize = 2 { set encap to task__encapsulate_method_2@. }
		else if argsize = 3 { set encap to task__encapsulate_method_3@. }
		else if argsize = 4 { set encap to task__encapsulate_method_4@. }
		else { print "Unsupported functions size" + argsize. exit. }
		
		local bound to encap:bind(typename + "." + key):bind(concurrent[key][0]).
		
		set result["prototype"][key] to bound.
	}
	
	return result.
}