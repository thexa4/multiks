run once os.
run once engine.
run once alignment.
run once task.

global ascent to object_concurrent("ascent", "object", lexicon(
	"running", false,
	"startAlt", 100,
	"state", 0,
	"start", ascent__start@,
	"stop", ascent__stop@
), lexicon(
	"step", list(ascent__step@, 0)
)).
set ascent["task"] to Task["dummy"]("Ascent").
set ascent["task"]["status"] to "WAITINGTORUN".

function ascent__start {
	parameter this, alt_desired.
	
	local result to Task["fromFunc"](ascent__init@:bind(this):bind(alt_desired), "Ascent").
	set ascent["task"] to result.
	return result.
}

function ascent__init {
	parameter this, alt_desired, runtask.
	
	print "Ascending to " + alt_desired.
	
	if(not task__setup(ascent["task"])) {
		print "Ascent already running!".
		exit.
	}
	
	set this["_altDesired"] to alt_desired.
	set this["state"] to ascent_step_straight@.
	os["instance"]["schedule"](this["step"], "ascent_step", os_lock_default).
	
	engine["instance"]["setThrottle"](1).
	engine["instance"]["setAutostage"](1).
	alignment["instance"]["setSteering"](HEADING(90, 90)).
	
	return.
}

function ascent__stop {
	parameter this.
	if ascent["task"]["status"] <> "RUNNING" {
		print "Error: ascent stop without start".
		return false.
	}
	
	if (SHIP:OBT:PERIAPSIS <= 0.97 * this["_altDesired"]) {
		ascent["task"]["setError"]("Canceled").
	} else {
		ascent["task"]["setResult"]("Finished").
	}
	
	os["instance"]["unschedule"]("ascent_step").
	engine["instance"]["unlockThrottle"]().
	engine["instance"]["setAutostage"](0).
	alignment["instance"]["unlock"]().
	
	return true.
}

function ascent__step {
	parameter this.
	
	if ascent["task"]["status"] <> "RUNNING" {
		print "Warning, ascent step without start".
		return.
	}
	
	set ress to ship:resources.
	for res in ress {
		if (res:name = "LIQUIDFUEL") {
			if (res:amount < 0.01) {
				print "Unable to complete ascent due to lack of resources.".
				this["stop"]().
			}
			break.
		}
	}
	
	this["state"]:call(this).
	
	return true.
}

function ascent_step_straight {
	parameter this.
	if ALT:RADAR < this["startAlt"] {
		return.
	}
	
	set this["state"] to ascent_step_curve@.
}

function ascent_step_curve {
	parameter this.
	alignment["instance"]["setSteering"](HEADING(90, 90 * ((this["_altDesired"] - ALT:RADAR - this["startAlt"]) / (this["_altDesired"] - this["startAlt"])) * ((this["_altDesired"] - ALT:RADAR - this["startAlt"]) / (this["_altDesired"] - this["startAlt"])))).
	
	if SHIP:OBT:APOAPSIS < this["_altDesired"] {
		return.
	}
	
	engine["instance"]["setThrottle"](0).
	
	set this["state"] to ascent_step_coasting@.
}

function ascent_step_coasting {
	parameter this.
	set warpmode to "physics".
	set warp to 3.

	if eta:apoapsis > 35 {
		return.
	}
	
	set warp to 0.
	wait 0.01.
	
	alignment["instance"]["setSteering"](HEADING(90, 0)).
	engine["instance"]["setThrottle"](0.05).
	
	set this["_bestEcc"] to 1.
	
	set this["state"] to ascent_step_circularize@.
}

function ascent_step_circularize {
	parameter this.
	
	if SHIP:OBT:PERIAPSIS >= 0.97 * this["_altDesired"] {
		//print "Orbit reached".
		this["stop"]().
		return.
	}
	
	if(alignment["instance"]["isAligned"]()) {
		engine["instance"]["setThrottle"](1).
	} else {
		return.
	}
	
	if (ship:orbit:eccentricity > this["_bestEcc"] + 0.02) {
		//print "Eccentricity (" + ship:orbit:eccentricity + ") worse than " + (this["_bestEcc"] + 0.02).
		this["stop"]().
		return.	
	}
	
	if (ship:orbit:eccentricity < this["_bestEcc"]) {
		set this["_bestEcc"] to ship:orbit:eccentricity.
	}
}