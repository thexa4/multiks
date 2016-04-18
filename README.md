# Multiks
KSP KOS timesharing OS

## What does this do?
This set of scripts allows you to write missions by using asynchronous building blocks. This enables you to run things like code guarding energy levels while other code is executing as well. 

## Objects
Objects in Multiks work a bit like javascript objects, they exist as a prototype and are instanciated by copying the prototype to a new location. You can create an object like this:

    local o to object["new"]().

All objects are made from a lexicon, functions written for objects are automatically bound to the object itself so it can call functions on itself. Some objects are singletons, they create a default instance on the type itself with the property name "instance".

## Tasks
All units of work are defined using Task objects. They follow the C# Task where possible but due to the lack of anonymous functions behave a bit differently in some ways.