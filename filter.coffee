module.exports = (env) ->
  events = require 'events'
  Promise = env.require 'bluebird'
  types = env.require('decl-api').types
  assert = env.require 'cassert'
  _ = env.require('lodash')
  commons = require('pimatic-plugin-commons')(env)

  class AttributeContainer extends events.EventEmitter
    constructor: () ->
      @values = {}

  class FilterPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      @debug = @config.debug || false
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("SimpleMovingAverageFilter", {
        configDef: deviceConfigDef.SimpleMovingAverageFilter,
        createCallback: (config, lastState) =>
          return new SimpleMovingAverageFilter(config, lastState)
      })

      @framework.deviceManager.registerDeviceClass("SimpleTruncatedMeanFilter", {
        configDef: deviceConfigDef.SimpleTruncatedMeanFilter,
        createCallback: (config, lastState) =>
          return new SimpleTruncatedMeanFilter(config, lastState)
      })

      @framework.deviceManager.registerDeviceClass("SimpleRateOfChangeFilter", {
        configDef: deviceConfigDef.SimpleRateOfChangeFilter,
        createCallback: (config, lastState) =>
          return new SimpleRateOfChangeFilter(config, lastState)
      })

  plugin = new FilterPlugin

  class FilterBase extends env.devices.Device
    actions:
      resetStats:
        description: "Resets the stats attribute values"

    statsAttributeTemplates:
      source:
        description: "Source value"
        type: types.number
        acronym: 'src'
        unit: 'source'
      min:
        description: "Minimum value"
        type: types.number
        acronym: 'min'
        unit: 'source'
      max:
        description: "Maximum value"
        type: types.number
        acronym: 'max'
        unit: 'source'
      mean:
        description: "Mean value"
        type: types.number
        acronym: 'mean'
        unit: 'source'
      increase:
        description: "Increase"
        type: types.number
        acronym: 'inc'
        unit: 'source'
      percentChange:
        description: "Percentage change"
        type: types.number
        acronym: 'pc'
        unit: '%'

    math:
      source: (values) -> unless values.length is 0 then values[values.length - 1] else Infinity
      min: (values) -> Math.min.apply @, values
      max: (values) -> Math.max.apply @, values
      mean: (values) ->
        # arithmetic mean, also referred to as the average
        unless values.length is 0
          values.reduce((a, b) -> a + b) / values.length
        else
          Infinity
      increase: (values) =>
        result = Infinity
        unless values.length is 0
          if @_previousValueIncrease?
            value = values[values.length - 1]
            result = value - @_previousValueIncrease
            @_previousValueIncrease = value
          else
            @_previousValueIncrease = values[values.length - 1]
            result = 0.0
        return result
      percentChange: (values) =>
        result = Infinity
        unless values.length is 0
          if @_previousValuePercentChange?
            value = values[values.length - 1]
            result = 100 * (value - @_previousValuePercentChange) / @_previousValuePercentChange
            @_previousValuePercentChange = value
          else
            @_previousValuePercentChange = values[values.length - 1]
            result = 0.0
        return result

    constructor: (@config, lastState) ->
      @attributes = _.cloneDeep(@attributes)
      @statsAttributeValues = new AttributeContainer()
      @debug = plugin.debug || false
      @base = commons.base @, @config.class
      @output = @config.output
      @varManager = plugin.framework.variableManager #so you get the variableManager

      name = @output.name
      @outputAttributeValue = if lastState?[name]? then lastState[name].value else null
      @attributes = _.cloneDeep(@attributes)
      @attributes[name] = {
        description: name
        label: (if @output.label? then @output.label else "$#{name}")
        type: "number"
      }

      if @output.unit? and @output.unit.length > 0
        unless @output.unit is 'auto'
          @attributes[name].unit = @output.unit
        else
          @_deferredUpdate () =>
            info = @varManager.parseVariableExpression(@output.expression)
            unit = @varManager.inferUnitOfExpression(info.tokens)
            unit += '/' + @timeBase if unit? and @timeBase?
            @attributes[@output.name].unit = unit

      if @output.discrete?
        @attributes[name].discrete = @output.discrete

      if @output.acronym?
        @attributes[name].acronym = @output.acronym

      @_createGetter(name, =>
        return Promise.resolve @outputAttributeValue
      )

      # initialize stats attributes
      for attributeName in @config.stats
        do (attributeName) =>
          if _.has @statsAttributeTemplates, attributeName
            properties = @statsAttributeTemplates[attributeName]
            @attributes[attributeName] =
              description: properties.description
              type: properties.type
              acronym: properties.acronym if properties.acronym?

            if properties.unit?
              if properties.unit isnt 'source'
                @attributes[attributeName].unit = properties.unit
              else
                @_deferredUpdate () =>
                  info = @varManager.parseVariableExpression(@output.expression)
                  sourceUnit = @varManager.inferUnitOfExpression(info.tokens)
                  @attributes[attributeName].unit = sourceUnit

            defaultValue = null # if properties.type is types.number then 0.0 else '-'
            @statsAttributeValues.values[attributeName] = lastState?[attributeName]?.value or defaultValue

            @statsAttributeValues.on attributeName, ((value) =>
              @base.debug "Received update for attribute #{attributeName}: #{value}"
              @statsAttributeValues.values[attributeName] = value
              @emit attributeName, value if value?
            )

            @_createGetter(attributeName, =>
              return Promise.resolve @statsAttributeValues.values[attributeName]
            )
          else
            @base.error "Configuration Error. No such attribute: #{attributeName} - skipping."

      @resetStatsHandler = (device) =>
        if device.id is @.id
          @base.debug "Device has changed - resetting stats"
          @resetStats()
          @_previousValuePercentChange = null
          @_previousValueIncrease = null
      plugin.framework.once 'deviceChanged', @resetStatsHandler
      super()

    destroy: () ->
      plugin.framework.removeListener 'deviceChanged', @resetStatsHandler
      super()

    _setAttribute: (attributeName, value) ->
      @outputAttributeValue = value
      @emit attributeName, value

    _updateStats: (val) ->
      for own key of @statsAttributeValues.values
        v = @statsAttributeValues.values[key]
        result = @math[key] if v? then [v, val] else [val]
        @statsAttributeValues.emit key, result

    _deferredUpdate: (update) ->
      if @varManager.inited
        update()
      else
        @varManager.waitForInit().then => update()

    _getNumber: (value) ->
      if value?
        numValue = Number value
        unless isNaN numValue
          return numValue
        else
          errorMessage = "Input value is not a number: #{value}"
      else
        errorMessage = "Input value is null or undefined"
      throw new Error errorMessage

    resetStats: () ->
      for own key of @statsAttributeValues.values
        @statsAttributeValues.emit key, null

  class SimpleMovingAverageFilter extends FilterBase
    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @size = @config.size
      @filterValues = []
      @sum = 0.0
      @mean = 0.0
      @math.mean = () => @mean

      @_exprChangeListeners = []
      super(@config, lastState)

      info = null
      evaluate = ( =>
        # wait till VariableManager is ready
        return @varManager.waitForInit().then( =>
          unless info?
            info = @varManager.parseVariableExpression(@output.expression)
            @varManager.notifyOnChange(info.tokens, evaluate)
            @_exprChangeListeners.push evaluate

          switch info.datatype
            when "numeric" then @varManager.evaluateNumericExpression(info.tokens)
            when "string" then @varManager.evaluateStringExpression(info.tokens)
            else
              assert false
        ).then((val) =>
          val = @_getNumber(val)
          @filterValues.push val
          @sum = @sum + val
          if @filterValues.length > @size
            @sum = @sum - @filterValues.shift()
          @mean = @sum / @filterValues.length

          @_setAttribute @output.name, @mean
          @_updateStats val

          return @outputAttributeValue
        ).catch((error) =>
          @base.error "Error on device #{@config.id}:", error.message
        )
      )
      evaluate()

    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()


  class SimpleTruncatedMeanFilter extends FilterBase

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @size = @config.size
      @filterValues = []
      @mean = 0.0
      @math.mean = () => @mean

      @_exprChangeListeners = []

      super(@config, lastState)

      info = null
      evaluate = ( =>
        # wait till VariableManager is ready
        return @varManager.waitForInit().then( =>
          unless info?
            info = @varManager.parseVariableExpression(@output.expression)
            @varManager.notifyOnChange(info.tokens, evaluate)
            @_exprChangeListeners.push evaluate

          switch info.datatype
            when "numeric" then @varManager.evaluateNumericExpression(info.tokens)
            when "string" then @varManager.evaluateStringExpression(info.tokens)
            else
              assert false
        ).then((val) =>
          val = @_getNumber(val)
          @filterValues.push val
          if @filterValues.length > @size
            @filterValues.shift()

          processedValues = _.clone(@filterValues)
          if processedValues.length > 2
            processedValues.sort()
            processedValues.shift()
            processedValues.pop()

          @mean = processedValues.reduce(((a, b) => return a + b), 0) / processedValues.length
          @_setAttribute @output.name, @mean
          @_updateStats val

          return @outputAttributeValue
        ).catch((error) =>
          @base.error "Error on device #{@config.id}:", error.message
        )
      )
      evaluate()

    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()


  class SimpleRateOfChangeFilter extends FilterBase

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @size = @config.size
      @timeBase = @config.timeBase
      @scale = @config.scale
      @previousValue = 0.0
      @previousTime = 0
      @rateOfChange = 0.0

      @_exprChangeListeners = []

      super(@config, lastState)

      info = null
      evaluate = ( =>
        # wait till VariableManager is ready
        return @varManager.waitForInit().then( =>
          unless info?
            info = @varManager.parseVariableExpression(@output.expression)
            @varManager.notifyOnChange(info.tokens, evaluate)
            @_exprChangeListeners.push evaluate

          switch info.datatype
            when "numeric" then @varManager.evaluateNumericExpression(info.tokens)
            when "string" then @varManager.evaluateStringExpression(info.tokens)
            else
              assert false
        ).then((val) =>
          val = @_getNumber(val)
          time = new Date()
          switch @timeBase
            when "second" then time /= 1000
            when "minute" then time /= 60000
            when "hour" then time /= 3600000

          valDifference = val - @previousValue
          timeDifference = time - @previousTime

          @rateOfChange =  valDifference / timeDifference

          @base.debug "name: #{@name}"
          @base.debug "output attribute: #{@output.name}"
          @base.debug "valDifference: #{valDifference}"
          @base.debug "timeDifference: #{timeDifference}"
          @base.debug "rateOfChange: #{@rateOfChange}"

          @base.debug "@previousTime: #{@previousTime}"
          unless @previousTime is 0
            #we skip the first update because we don't have previous values yet
            @_setAttribute @output.name, @rateOfChange

          @_updateStats val
          @previousTime = time
          @previousValue = val

          return @outputAttributeValue
        ).catch((error) =>
          @base.error "Error on device #{@config.id}:", error.message
        )
      )
      evaluate()

    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()


  return plugin
