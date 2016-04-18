global orbitutils to lexicon(
	"hohmann", orbitutils__hohmann@
).

function orbitutils__hohmann {
	parameter target, target_periapsis.
	
	// From https://www.reddit.com/r/Kos/comments/3xihu7/automated_mun_science_return_probe/?
	set target_periapsis to target_periapsis*1000.

	local my_radius to SHIP:OBT:SEMIMAJORAXIS.
	// wen want to get into to soi but not into the planet target
	local tgt_radius to (target:OBT:SEMIMAJORAXIS - target:RADIUS   - target_periapsis -(target:SOIRADIUS/10) ).

	// Hohmann Transfer Time
	local transfer_time to constant():pi * sqrt((((my_radius + tgt_radius)^3)/(8*target:BODY:MU))).
	local phase_angle to (180*(1-(sqrt(((my_radius + tgt_radius)/(2*tgt_radius))^3)))).
	local actual_angle to mod(360 + target:LONGITUDE - SHIP:LONGITUDE,360) .
	local d_angle to (mod(360 + actual_angle - phase_angle,360)).

	local ship_ang to  360/SHIP:OBT:PERIOD.
	local tgt_ang to  360/TARGET:OBT:PERIOD.
	local d_ang to ship_ang - tgt_ang.
	local d_time to d_angle/d_ang.

	local my_dV to sqrt (target:BODY:MU/my_radius) * (sqrt((2* tgt_radius)/(my_radius + tgt_radius)) - 1).

	return 
	
	return NODE(time:seconds+d_time, 0, 0, my_dV).
}