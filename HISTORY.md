# Release History

* 2016914, V0.8.9
    * Fixed erroneous assignment of lastState to attribute values on device initialization, issue #4
    * Added Release History
    
* 20160528, V0.8.8
    * Implemented destroy methods as required for pimatic 0.9

* 20160408, V0.8.7
    * Fixed compatibility issue with Coffeescript 1.9 as required for pimatic 0.9
    * Updated peerDependencies property for compatibility with pimatic 0.9

* 20160218, V0.8.6
    * Improved errir for handling for parsed expression values, issue #2
    * Corrected device-config-schema: "unit", "label", and "discrete" are now optional as described in README, issue #2
    * Removed "type" property from example in README, issue #2

* 20160218, V0.8.5
    * Clone attributes before adding a new attribute. Fix for issues #2 and #3

* 20151205, V0.8.4
    * Improved error handling (issue #1)
    * Fixed typo

* 20151122, V0.8.3
    * Changed initialization order to avoid race condition while evaluating the variable expression for the first time.
    * Fixed typo.

* 20151018, V0.8.2
    * Revised README
    * Fixed bug: filterValues array and other supporting members must be instance variables instead of class variables.

* 20151018, V0.8.1
    * Bug fix: Check if lastState is undefined which may the case on the first run

* 20151018, V0.8.0
    * Initial release