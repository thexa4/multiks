run once object.

global multithread__tick_count to 0.
global multithread__tick_counting to false.

global multithread to object_inherit("multithread", "object", lexicon(
	"running", false,
	"queue", queue(),
	"current", "stopped",
	"timeout", multithread__ops_to_cycles(1250),
	"start", multithread__start@,
	"trace", multithread__trace@,
	"run", multithread__run@
)).

function multithread__ops_to_cycles {
	parameter ticks.
	
	if (ticks = 0) { return 0. }
	
	return max(1, ceiling(ticks / config:ipu)).
}

set multithread["instance"] to multithread["new"]().

function multithread__start {
	parameter this.
	
	if this["running"] {
		print "Error: Recursive run in multithread, aborting".
		this["trace"]().
		exit.
	}
		
	set this["running"] to true. 
	local q to this["queue"].
	
	if this["timeout"] <> 0 {
		set multithread__tick_counting to true.
		when true then {
			set multithread__tick_count to multithread__tick_count + 1. return multithread__tick_counting.
		}
	}
	
	until q:empty {
	
		global multithread__tick_count to 0.
		local currentcall to q:pop.
		
		local del to currentcall["delegate"].
		set this["current"] to currentcall["description"].
		
		del:call().
		
		local stopcount to multithread__tick_count.
		
		if this["timeout"] <> 0 {
			if stopcount > this["timeout"] {
				print "Warning: Execution took too long: (" + stopcount + " > " + this["timeout"] + " ticks)".
				this["trace"]().
			}
		}
		
	}
	
	set this["running"] to false.
	set multithread__tick_counting to false.
}

function multithread__run {
	declare parameter this, del, debug_name.
	
	this["queue"]:push(lexicon("delegate", del, "description", debug_name)).
}

function multithread__trace {
	parameter this.
	print "Currently running: " + this["current"].
	print "Call queue:".
	for item in this["queue"] {
		print item["description"].
	}
}