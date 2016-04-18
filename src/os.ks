run once task.

global os_lock_realtime to 100.
global os_lock_high to 75.
global os_lock_default to 50.
global os_lock_low to 25.
global os_lock_idle to 0.

global os to object_inherit("os", "object", lexicon(
	// concurrent
	"idle", list(),
	"running", false,
	"lockLevel", 0,
	"lockList", list(),
	"lock", os__lock@,
	"unlock", os__unlock@,
	"calc_lock", os__calc_lock@,
	"init", os__init@,
	"schedule", os__schedule@,
	"unschedule", os__unschedule@,
	"shutdown", os__shutdown@,
	"start", os__start@
)).

print "Multiks 0.2".
set os["instance"] to os["new"]().


function os__lock {
	parameter this, priority.
	
	this["lockList"]:add(priority).
}

function os__unlock {
	parameter this, priority.
	local i to 0.
	local found to -1.
	
	for pri in this["lockList"] {
		if pri = priority {
			set found to i.
			break.
		}
		local i to i + 1.
	}
	
	if found >= 0 {
		this["lockList"]:remove(found).
	} else {
		print "Lock remove failed, lock not found.".
	}
}

function os__calc_lock {
	set this["lockLevel"] to 0.
	for pri in this["lockList"] {
		if pri > this["lockLevel"] {
			set this["lockLevel"] to pri.
		}
	}
}

function os__init {
	parameter this.
	print "Elevated to runlevel 1".
	multithread["instance"]["start"]().
}

function os__schedule {
	parameter this, delegate, description, priority.
	//print "Starting service " + description.
	
	this["idle"]:add(list(delegate, description, priority)).
}

function os__unschedule {
	parameter this, description.
	
	//print "Stopping service " + description.
	
	local i to 0.
	local found to -1.
	for service in this["idle"] {
		if service[1] = description {
			set found to i.
			break.
		}
		local i to i + 1.
	}
	
	if found > -1 {
		this["idle"]:remove(found).
	} else {
		print "Warning: OS unschedule failed!".
	}
}

function os__shutdown {
	parameter this.
	set this["running"] to false.
	print "Shutdown received, stopping running programs".
	print "Press ctrl+c to stop immediately".
}

function os__start {
	parameter this.
	set this["running"] to true.
	print "Elevated to runlevel 2".

	until not this["running"] {
		
		for service in this["idle"] {
			if service[2] >= this["lockLevel"] {
				local task to service[0]:call().
				task_start(task).
			}
		}
		
		multithread["instance"]["start"]().
		
		if this["idle"]:length = 0 {
			set this["running"] to false.
		}
	}

	print "Dropping to runlevel 0".
}