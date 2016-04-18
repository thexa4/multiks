run once os.
run once engine.
run once alignment.
run once task.

global atmoland to object_concurrent("atmoland", "object", lexicon(
	"running", false,
	"state", 0,
	"start", atmoland__start@,
	"stop", atmoland__stop@
), lexicon(
	"step", list(atmoland__step@, 0)
)).
set atmoland["task"] to Task["dummy"]("Atmo land").
set atmoland["task"]["status"] to "RANTOCOMPLETION".

function atmoland__start {
	parameter this.
	
	local result to task["fromFunc"](atmoland__init@:bind(this), "Atmo land").
	set atmoland["task"] to result.
	return result.
}

function atmoland__init {
	parameter this, runtask.
	
	print "Landing...".
	
	if(not task__setup(atmoland["task"])) {
		print "Landing already running!".
		exit.
	}

	set this["state"] to atmoland_step_reach_atmo@.
	os["instance"]["schedule"](this["step"], "atmoland_step", os_lock_default).
	
	//engine["instance"]["setThrottle"](0).
	engine["instance"]["setAutostage"](1).
	
	return.
}

function atmoland__stop {
	parameter this.
	if atmoland["task"]["status"] <> "RUNNING" {
		print "Error: atmoland stop without start".
		return false.
	}
	
	if (alt:radar < 10 or ship:airspeed < 0.05) {
		atmoland["task"]["setError"]("Canceled").
	} else {
		atmoland["task"]["setResult"]("Finished").
	}
	
	os["instance"]["unschedule"]("atmoland_step").
	engine["instance"]["unlockThrottle"]().
	engine["instance"]["setAutostage"](0).
	alignment["instance"]["unlock"]().
	
	return true.
}

function atmoland__step {
	parameter this.
	
	if atmoland["task"]["status"] <> "RUNNING" {
		print "Warning, atmoland step without start".
		return.
	}
	
	this["state"]:call(this).
	
	return true.
}

function atmoland_step_reach_atmo {
	parameter this.
	
	if (alt:periapsis < body:atm:height * 0.85) {
		set this["state"] to atmoland__airbreak_rails_5@.
		engine["instance"]["unlockThrottle"]().
		alignment["instance"]["unlock"]().
		
		return.
	}
	
	alignment["instance"]["setSteering"](RETROGRADE:vector).
	if (alignment["instance"]["isAligned"]()) {
		engine["instance"]["setThrottle"](1).
	} else {
		engine["instance"]["unlockThrottle"]().
	}
}

function atmoland__airbreak_rails_5 {
	parameter this.
	
	if (ship:altitude < 200000) {
		set this["state"] to atmoland__airbreak_rails_1@.
		return.
	}
	
	if (warp <> 5) {
		set warpmode to "rails".
		set warp to 5.
	}
}

function atmoland__airbreak_rails_1 {
	parameter this.
	
	if (ship:altitude < body:atm:height * 1.15) {
		set this["state"] to atmoland__airbreak_physics_3@.
		return.
	}
	
	if (ship:altitude > 200000) {
		set this["state"] to atmoland__airbreak_rails_5@.
		return.
	}
	
	if (warp <> 1) {
		set warpmode to "rails".
		set warp to 1.
	}
}

function atmoland__airbreak_physics_3 {
	parameter this.
	
	alignment["instance"]["setSteering"](RETROGRADE:vector).
	if (warp <> 0 and not alignment["instance"]["isAligned"]()) {
		set warp to 0.
		return.
	}
	
	if (ship:altitude < body:atm:height * 0.85) {
		set this["state"] to atmoland__motorbreak@.
		return.
	}
	
	if (ship:altitude > body:atm:height * 1.15) {
		set this["state"] to atmoland__airbreak_rails_1@.
		return.
	}
	
	if (warp <> 3) {
		set warpmode to "physics".
		set warp to 3.
	}
}

function atmoland__motorbreak {
	parameter this.
	
	if (warp <> 0) {
		set warp to 0.
	}
	
	alignment["instance"]["setSteering"](RETROGRADE:vector).
	engine["instance"]["setThrottle"](1).
	
	if (ship:periapsis < 0) {
		engine["instance"]["unlockThrottle"]().
		set this["state"] to atmoland__unstage@.
	}
	
	if (ship:altitude > body:atm:height * 0.85) {
		engine["instance"]["unlockThrottle"]().
		set this["state"] to atmoland__airbreak_physics_3@.
	}
}

function atmoland__unstage {
	parameter this.
	
	alignment["instance"]["setSteering"](RETROGRADE:vector).
	if (stage:number <> 1) {
		stage.
		return.
	}
	
	set this["state"] to atmoland__coasting@.
}

function atmoland__coasting {
	parameter this.
	
	alignment["instance"]["setSteering"](RETROGRADE:vector).
	
	if (ship:airspeed < 260) {
		stage.
		alignment["instance"]["freeFall"]().
		set this["state"] to atmoland__parachute@.
	}
}

function atmoland__parachute {
	parameter this.
	
	if (alt:radar < 10 or ship:airspeed < 0.05) {
		this["stop"]().
	}
}