module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  _ = env.require('lodash')

  class FilterPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
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

  plugin = new FilterPlugin

  class SimpleMovingAverageFilter extends env.devices.Device

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @size = @config.size
      @output = @config.output
      @filterValues = []
      @sum = 0.0
      @mean = 0.0

      @varManager = plugin.framework.variableManager
      @_exprChangeListeners = []

      name = @output.name
      @attributeValue = if lastState?[name]? then lastState[name] else 0
      @attributes = _.cloneDeep(@attributes)
      @attributes[name] = {
        description: name
        label: (if @output.label? then @output.label else "$#{name}")
        type: "number"
      }

      if @output.unit? and @output.unit.length > 0
        @attributes[name].unit = @output.unit

      if @output.discrete?
        @attributes[name].discrete = @output.discrete

      if @output.acronym?
        @attributes[name].acronym = @output.acronym

      @_createGetter(name, =>
        return Promise.resolve @attributeValue
      )
      super()

      info = null
      evaluate = ( =>
        # wait till VariableManager is ready
        return Promise.delay(10).then( =>
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

          env.logger.debug @mean, @filterValues
          @_setAttribute name, @mean

          return @attributeValue
        ).catch((error) =>
          env.logger.error "Error on device #{@config.id}:", error.message
        )
      )
      evaluate()

    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()

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

    _setAttribute: (attributeName, value) ->
      @attributeValue = value
      @emit attributeName, value


  class SimpleTruncatedMeanFilter extends env.devices.Device

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @size = @config.size
      @output = @config.output
      @filterValues = []
      @mean = 0.0

      @varManager = plugin.framework.variableManager #so you get the variableManager
      @_exprChangeListeners = []

      name = @output.name
      @attributeValue = if lastState?[name]? then lastState[name] else 0
      @attributes = _.cloneDeep(@attributes)
      @attributes[name] = {
        description: name
        label: (if @output.label? then @output.label else "$#{name}")
        type: "number"
      }

      if @output.unit? and @output.unit.length > 0
        @attributes[name].unit = @output.unit

      if @output.discrete?
        @attributes[name].discrete = @output.discrete

      if @output.acronym?
        @attributes[name].acronym = @output.acronym

      @_createGetter(name, =>
        return Promise.resolve @attributeValue
      )
      super()

      info = null
      evaluate = ( =>
        # wait till VariableManager is ready
        return Promise.delay(10).then( =>
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

          env.logger.debug @mean, @filterValues, processedValues
          @_setAttribute name, @mean

          return @attributeValue
        ).catch((error) =>
          env.logger.error "Error on device #{@config.id}:", error.message
        )
      )
      evaluate()

    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()

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

    _setAttribute: (attributeName, value) ->
      @attributeValue = value
      @emit attributeName, value

  return plugin
