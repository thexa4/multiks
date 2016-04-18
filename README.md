# Multiks
KSP KOS timesharing OS

## What does this do?
This set of scripts allows you to write missions by using asynchronous building blocks. This enables you to run things like code guarding energy levels while other code is executing as well or perform conditional autostaging in the background without using triggers (already implemented). 

## Objects
Objects in Multiks work a bit like javascript objects, they exist as a prototype and are instanciated by copying the prototype to a new location. You can create an object like this:

    local o to object["new"]().

All objects are made from a lexicon, functions written for objects are automatically bound to the object itself so it can call functions on itself. Some objects are singletons, they create a default instance on the type itself with the property name "instance".

## Tasks
All units of work are defined using Task objects. They follow the C# Task where possible but due to the lack of anonymous functions behave a bit differently in some ways.

## Remarks
This set of scripts works best at higher IPU configurations but has been tested to work up til 50 if not too many scripts fight for resources.

## Example
An example boot file:

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
    
    // Initializes the run loop data structures.
    os["instance"]["init"]().
    
    // Your own function
    function doScience {
    	toggle brakes.
    }
    
    // The objects representing the algorithm for ascending and landing.
    local ascentObj to ascent["new"]().
    local landObj to atmoland["new"]().
    
    // The invidual tasks representing all steps in the mission
    local ascentTask to ascentObj["start"](100000).
    local warpTask to warpmanager["instance"]["warpTo"](time:seconds + 1000).
    local scienceTask to task["create"](doScience@, "science").
    local landTask to landObj["start"]().
    local scienceTask2 to task["create"](doScience@, "science").
    
    // Defining how the steps should be ordered and what should run after what.
    ascentTask["continueWith"](warpTask).
    warpTask["continueWith"](scienceTask).
    scienceTask["continueWith"](landTask).
    landTask["continueWith"](scienceTask2).
    
    // Queue the first task to be run.
    start(ascentTask).
    
    // Before this line nothing will actually run. This is the event loop.
    os["instance"]["start"]().

