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

//run once ascent.
//run once atmoland.
//run once orbitutils.

run once warputils.

os["instance"]["init"]().
local tgt to time:seconds + 60000.

function calcdiff {
	print tgt - time:seconds.
}

local lt1 to warpManager["instance"]["warpTo"](tgt).
start(lt1).

lt1["continueWith"](task["create"](calcdiff@, "diff")).

os["instance"]["start"]().