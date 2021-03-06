# Release History

* 20190912, V0.9.5
    * Fixed time-based update timer didn't register on next update cycle
    * Dependency updates
    
* 20180331, V0.9.4
    * Added support for time-based update of the filter variable
    * Dependency updates
    * Refactoring
    
* 20161228, V0.9.3
    * Stats attributes are now reset to the last input value processed
    * Fixed resetStats did not return promise
    
* 20161227, V0.9.2
    * Added reset action provider
    * Fixed filter default output attribute label
    * Fixed resetStats did not update display
    * Excluded 'src' attribute from reset
    
* 20161128, V0.9.1
    * Fixed setting unit from source attribute which caused an 
      initialization problem with the VariableManager, issue #11 
    * Refactoring
    
* 20161118, V0.9.0
    * Added new filter for Simple Rate of Change contributed by @thexperiments
    * Support for statistical attributes which can be added easily to the device configuration, issue #7
    * Refactoring
    * Dropped support for node 0.10 (pimatic 0.8)
    * Revised README

* 20160914, V0.8.9
    * Fixed erroneous assignment of lastState to attribute values on device initialization, issue #4
    * Added Release History
    
* 20160528, V0.8.8
    * Implemented destroy methods as required for pimatic 0.9

* 20160408, V0.8.7
    * Fixed compatibility issue with Coffeescript 1.9 as required for pimatic 0.9
    * Updated peerDependencies property for compatibility with pimatic 0.9

* 20160218, V0.8.6
    * Improved error for handling for parsed expression values, issue #2
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