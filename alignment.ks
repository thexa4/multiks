run once object.

global alignment to object_inherit("alignment", "object", lexicon(
	"setSteering", alignment__set_steering@,
	"isAligned", alignment__is_aligned@,
	"unlock", alignment__unlock@,
	"freeFall", alignment__free_fall@
)).

set alignment["instance"] to alignment["new"]().
//set alignment["idleDir"] to alignment__calc_idle_dir().

function alignment__set_steering {
	parameter this, arg_steering.
	
	set this["_target"] to arg_steering.
	lock steering to arg_steering.
}

function alignment__unlock {
	parameter this.
	local solardir to alignment__calc_idle_dir().
	lock steering to solardir.
}

function alignment__free_fall {
	parameter this.
	unlock steering.
}

function alignment__is_aligned {
	parameter this.
	
	local target to this["_target"].
	if (target:typename = "Direction") {
		set target to target:vector.
	}
	
	return ship:facing:vector * target:normalized > 0.999.
}

function alignment__calc_idle_dir {
	local basedir to body("Sun"):direction:vector.
	
	local solarvec to v(0,0,0).
	list parts in parts.
	for part in parts {
		for module in part:modules {
			if (module = "ModuleDeployableSolarPanel") {
				set solarvec to solarvec + part:facing:vector.
			}
		}
	}
	if (solarvec:mag < 0.05) {
		set solarvec to up:vector.
	}
	
	return rotatefromto(solarvec:normalized, basedir).
}