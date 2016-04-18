copy os from 0.
copy object from 0.
copy multithread from 0.
copy alignment from 0.
copy engine from 0.
copy ascent from 0.
copy atmoland from 0.
copy task from 0.
copy orbitutils from 0.
copy warputils from 0.
copy service from 0.
copy maneuver from 0.

run once ascent.
run once atmoland.
run once warputils.

os["instance"]["init"]().

function doScience {
	toggle brakes.
}

local ascentObj to ascent["new"]().
local landObj to atmoland["new"]().

local ascentTask to ascentObj["start"](100000).
local warpTask to warpmanager["instance"]["warpTo"](time:seconds + 1000).
local scienceTask to task["create"](doScience@, "science").
local landTask to landObj["start"]().
local scienceTask2 to task["create"](doScience@, "science").

ascentTask["continueWith"](warpTask).
warpTask["continueWith"](scienceTask).
scienceTask["continueWith"](landTask).
landTask["continueWith"](scienceTask2).

start(ascentTask).

os["instance"]["start"]().