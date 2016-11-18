# pimatic-filter

# pimatic-filter

[![Npm Version](https://badge.fury.io/js/pimatic-filter.svg)](http://badge.fury.io/js/pimatic-filter)
[![Build Status](https://travis-ci.org/mwittig/pimatic-filter.svg?branch=master)](https://travis-ci.org/mwittig/pimatic-filter)
[![Dependency Status](https://david-dm.org/mwittig/pimatic-filter.svg)](https://david-dm.org/mwittig/pimatic-filter)

Pimatic Plugin which provides various filtering functions to achieve digital filtering or smoothing of sensor data.
It is useful, for example, if the sensor data is not accurate and you wish to disregard potential outliers at
the minimum and maximum of sensor values processed.

## Status of Implementation

To date, the plugin provides three filter types. More filters can be added on request. If you wish to get involved
you're welcome to make contributions. If you're not familiar with programming please open issue to describe your  
request as detailed as possible including references to background material and possibly an algorithmic description.
If you like this plugin, please consider &#x2605; starring 
[the project on github](https://github.com/mwittig/pimatic-filter).

## Plugin Configuration

You can load the plugin by editing your `config.json` to include the following in the `plugins` section. However, it 
is recommended to use the plugin editor instead which is provided with the pimatic web frontend

    {
       "plugin": "filter",
       "debug": false
    }

## Filters Configuration

A filter basically is a pimatic device instance which takes an input value from another device which is processed to
produce an output value. Depending on the type of filter the number of output values produced may different from the
number of inputs provided.

### Simple Moving Average

The Simple Moving Average filter, is the unweighted mean of a given number of previous sensor values processed. For a
general discussion see [Wikipedia on Moving Average](https://en.wikipedia.org/wiki/Moving_average).

The number previous sensor values processed by the filter is called sliding window. You can specify the "size" of
the sliding window. By default, the window takes five elements. Initially, when the number of data values processed is
smaller than the window size, the mean will be calculated from the existing values.

The "output" property defines the attribute which represents the output produced by the filter. It must have a "name"
and an "expression" which defines a reference to the input value. In the simplest case, the expression contains a
variable, but it can also contain a calculation or a string interpolation which finally produces the input value.
Note, however, the resulting value must be a number to be processed by the filter. The "output" property may also 
contain a "label", "acronym", and "unit". If the "unit" value is set to "auto" the unit will be derived from the 
input attribute.

```json
    {
        "class": "SimpleMovingAverageFilter",
        "id": "filter1",
        "name": "Filter",
        "size": 5,
        "output": {
            "name": "temperature",
            "label": "Temperature",
            "expression": "$unipi-2.temperature",
            "acronym": "T",
            "unit": "°C"
        }
    }
```

### Simple Truncated Mean

The Simple Truncated Mean is a truncated mean, where the highest and lowest value of a given number of previous
sensor values is disregarded (truncated) and the remaining values are used to calculate the arithmetic mean. For a
general discussion see [Wikipedia on Truncated Mean](https://en.wikipedia.org/wiki/Truncated_mean).

The number previous sensor values processed by the filter is called sliding window. You can specify the "size" of
the sliding window. By default, the window takes five elements. Initially, when the number of data values processed is
smaller than the window size the mean will be calculated, as follows:
 * if there are less than three values,  no truncating is performed and the mean is calculated from the existing values
 * if there are three or more values, truncating is performed and the mean is calculated from the remaining values.

The "output" property defines the attribute which represents the output produced by the filter. It must have a "name"
and an "expression" which defines a reference to the input value. In the simplest case, the expression contains a
variable, but it can also contain a calculation or a string interpolation which finally produces the input value.
Note, however, the resulting value must be a number to be processed by the filter. The "output" property may also 
contain a "label", "acronym", and "unit". If the "unit" value is set to "auto" the unit will be derived from the 
input attribute.

```json
    {
        "class": "SimpleTruncatedMeanFilter",
        "id": "filter1",
        "name": "Filter",
        "output": {
            "name": "Temperature",
            "expression": "$unipi-2.temperature",
            "acronym": "T",
            "unit": "°C"
        }
    }
```

### Simple Moving Average

The Simple Moving Average provides the relative rate of value change per minute. It calculates the difference of two 
attribute value updates and divides it by the time difference of the updates. The rate scale can be changed 
from "minute" to "millisecond", "second" or "hour" by setting the "timeBase" property (see example below). Generally, 
it can be used to detect an unusual value change. An example use case for the Simple Moving Average is a humidity 
sensor in the bathroom where the rate of value change is used to detect if someone is taking a shower or the 
bathroom window has been opened (in wintertime).

The "output" property defines the attribute which represents the output produced by the filter. It must have a "name"
and an "expression" which defines a reference to the input value. In the simplest case, the expression contains a
variable, but it can also contain a calculation or a string interpolation which finally produces the input value.
Note, however, the resulting value must be a number to be processed by the filter. The "output" property may also 
contain a "label", "acronym", and "unit". If the "unit" value is set to "auto" the unit will be derived from the 
input attribute followed by the "timebase" fraction denominator.

```json
    {
        "class": "SimpleRateOfChangeFilter",
        "id": "filter2",
        "name": "Filter",
        "output": {
            "name": "rateOfChange",
            "expression": "$unipi-2.temperature",
            "acronym": "roc",
        },
        "timeBase": "minute"
    }
```

### Statistical Attributes (Stats)

![Screenshot](https://github.com/mwittig/pimatic-filter/raw/master/assets/screenshots/screenshot-device-view.png)

All device classes provide support for statistical attributes which can be added easily to the the device 
configuration:

* min - minimum value
* max - maximum value
* mean - arithmetic mean value
* increase - increase of the value in relation to the previous value
* percentChange - the percentage change of the value in relation to the previous value
* source - input value (provided here for convenience)

The attributes are added by setting the "stats" property of the device configuration which takes an array of string 
values. It is recommended to configure the attributes using the device editor provided with the pimatic web frontend as
shown in the screenshot below.

![Screenshot](https://github.com/mwittig/pimatic-filter/raw/master/assets/screenshots/screenshot-device-editor.png)

## History

See [Release History](https://github.com/mwittig/pimatic-filter/blob/master/HISTORY.md).

## License 

Copyright (c) 2015-2016, Marcus Wittig and contributors. All rights reserved.

[AGPL-3.0](https://github.com/mwittig/pimatic-filter/blob/master/LICENSE)
