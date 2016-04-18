run once service.
run once object.

global warplease to object_inherit("warplease", "object", lexicon(
	"warpMode", "rails",
	"warpSpeed", 1,
	"until", -1,
	"isValid", warplease__is_valid@,
	"min", warplease__min@
)).

function warplease__is_valid {
	parameter this.
	if (this["until"] = -1) {
		return true.
	}
	
	if (this["until"] < time:seconds) {
		return false.
	} else {
		return true.
	}
}

function warplease__min {
	parameter this, other.
	
	if (other = "undefined") {
		return this.
	}
	
	if (this["warpMode"] <> other["warpMode"])
	{
		if (this["warpMode"] = "rails") {
			return other.
		} else {
			return this.
		}
	}
	
	if (this["warpSpeed"] > other["warpSpeed"]) {
		return other.
	} else {
		return this.
	}
}

global warpmanager to object_inherit("warpmanager", "service", lexicon(
	"_setWarp", warpmanager__set@,
	"_stopWarp", warpmanager__unset@,
	"_unschedule", warpmanager__unschedule@,
	"_warpList", lexicon(),
	"requestWarp", warpmanager__request@,
	"releaseWarp", warpmanager__release@,
	"warpTo", warpmanager__warp_to@,
	"step", warpmanager__step@
)).

set warpmanager["instance"] to warpmanager["new"]().

function warpmanager__unset {
	parameter this.
	set warp to 0.
}

function warpmanager__set {
	parameter this, lease.
	
	set warpmode to lease["warpMode"].
	set warp to lease["warpSpeed"].
}

function warpmanager__unschedule {
	parameter this.
	
	if (not this["_running"]) {
		return.
	}
	
	this["_returnResult"](false).
	set warp to 0.
}

function warpmanager__request {
	parameter this, lease.
	
	set lease["task"] to task["fromFunc"](warpmanager__request_start@:bind(this):bind(lease), "warp lease").
	return lease["task"].
}

function warpmanager__request_start {
	parameter this, lease, runtask.
	
	task__setup(lease["task"]).
	
	//print lease["warpSpeed"].
	
	set this["_warpList"][lease] to true. //lexicon has O(1) remove.
	if(not this["_running"]) {
		start(this["_schedule"]("warpmanager service")).
	}
}

function warpmanager__release {
	parameter this, lease.
	
	if (not this["_warpList"]:haskey(lease)) {
		print "Warp lease not found, ignoring release.".
		return.
	}
	
	this["_warpList"]:remove(lease).
	if (this["_warpList"]:keys:length = 0) {
		this["_unschedule"]().
	}
	
	lease["task"]["setResult"](true).
}

function warpmanager__step {
	parameter this.
	
	local best to "undefined".
	local removes to list().
	
	for lease in this["_warpList"]:keys {
		if (lease["isValid"]()) {
			set best to lease["min"](best).
		} else {
			removes:add(lease).
		}
	}
	
	if (best <> "undefined") {
		this["_setWarp"](best).
	}
	
	for remove in removes {
		this["releaseWarp"](remove).
	}
}

function warpmanager__warp_to {
	parameter this, destination.
	
	local delta to destination - time:seconds - 5. // safety margin
	
	local result to task["new"]().
	local end to result.
	
	if (delta > 0) {
		local lease to warplease["new"]().
		set lease["warpSpeed"] to 1.
		set lease["until"] to destination.
		local prev to this["requestWarp"](lease).
		prev["continueWith"](result).
		set result to prev.
	}
	if (delta > 100) {
		local lease to warplease["new"]().
		set lease["warpSpeed"] to 2.
		set lease["until"] to destination - 100.
		local prev to this["requestWarp"](lease).
		prev["continueWith"](result).
		set result to prev.
	}
	if (delta > 250) {
		local lease to warplease["new"]().
		set lease["warpSpeed"] to 3.
		set lease["until"] to destination - 250.
		local prev to this["requestWarp"](lease).
		prev["continueWith"](result).
		set result to prev.
	}
	if (delta > 500) {
		local lease to warplease["new"]().
		set lease["warpSpeed"] to 4.
		set lease["until"] to destination - 500.
		local prev to this["requestWarp"](lease).
		prev["continueWith"](result).
		set result to prev.
	}
	if (delta > 4000) {
		local lease to warplease["new"]().
		set lease["warpSpeed"] to 5.
		set lease["until"] to destination - 4000.
		local prev to this["requestWarp"](lease).
		prev["continueWith"](result).
		set result to prev.
	}
	if (delta > 32000) {
		local lease to warplease["new"]().
		set lease["warpSpeed"] to 6.
		set lease["until"] to destination - 32000.
		local prev to this["requestWarp"](lease).
		prev["continueWith"](result).
		set result to prev.
	}
	if (delta > 64000) {
		local lease to warplease["new"]().
		set lease["warpSpeed"] to 7.
		set lease["until"] to destination - 64000.
		local prev to this["requestWarp"](lease).
		prev["continueWith"](result).
		set result to prev.
	}
	
	return task["wrapMultiple"](result, end, "warp sequence").
}