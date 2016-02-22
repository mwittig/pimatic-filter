# pimatic-filter

Pimatic Plugin which provides various filtering functions to achieve digital filtering or smoothing of sensor data.
It is useful, for example, if the sensor data is not accurate and you wish to disregard potential outliers at
the minimum and maximum of sensor values processed.

## Status of Implementation

To date, the plugin provides two basic filter types. More filters can be added on request. If you wish to get involved
you're welcome to make contributions. If you're not familiar with programming please open issue to describe your  
request as detailed as possible including references to background material and possibly an algorithmic description.

For a history of changes see also the [release log](https://github.com/mwittig/pimatic-filter/releases).

## Plugin Configuration

You can load the plugin by editing your `config.json` to include the following in the `plugins` section.

    {
       "plugin": "filter",
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
and a "expression" which defines a reference to the input value. In the simplest case, the expression contains a
variable, but it can also contain a calculation or a string interpolation which finally produces the input value.
Note, however, the resulting value must be a number to be processed by the filter. The "output" may also contain a 
"label", "acronym", and "unit".

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
and a "expression" which defines a reference to the input value. In the simplest case, the expression contains a
variable, but it can also contain a calculation or a string interpolation which finally produces the input value.
Note, however, the resulting value must be a number to be processed by the filter. The "output" may also contain a
"label", "acronym", and "unit".

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
