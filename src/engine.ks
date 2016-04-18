run once multithread.
run once os.

global engine to object_concurrent("engine", "object", lexicon(
	"_isAutostaging", false,
	"setThrottle", engine__set_throttle@,
	"unlockThrottle", engine__unlock_throttle@,
	"setAutostage", engine__set_autostage@,
	"autostageLimit", 0
), lexicon(
	"autostage", list(engine__autostage@, 0)
)).
 
set engine["instance"] to engine["new"]().

function engine__stage_resources {
	list parts in parts.

	local total to 0.
	for part in parts {
		if part:stage = stage:number {
			for res in part:resources {
				if (res:name = "LIQUIDFUEL") {
					set total to total + res:amount.
				}
			}
		}
	}
	return total.
}

function engine__shouldStage {
	parameter this.
	return stage:number > this["autostageLimit"] and (ship:maxthrust = 0).// or engine__stage_resources = 0).
}

function engine__set_throttle {
	parameter this, desired_throttle.
	
	global glb_engine_throttle to desired_throttle.
	lock throttle to glb_engine_throttle.
}

function engine__unlock_throttle {
	parameter this.
	
	unlock throttle.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}

function engine__set_autostage {
	parameter this, autostage.
	
	if autostage = this["_isAutostaging"] {
		return.
	}
	set this["_isAutostaging"] to autostage.
	
	if autostage {
		os["instance"]["schedule"](this["autostage"], "engine_autostage", os_lock_default).
	} else {
		os["instance"]["unschedule"]("engine_autostage").
	}
}

function engine__autostage {
	parameter this.
	if engine__shouldStage(this) {
		stage.
	}
}