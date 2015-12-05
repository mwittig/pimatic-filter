module.exports = {
  title: "pimatic-filter device config schemas"
  SimpleMovingAverageFilter: {
    title: "SimpleMovingAverageFilter config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      size:
        description: "Size of the sliding window of samples used for the calculation"
        type: "number"
        default: "5"
      output:
        type: "object"
        required: ["name", "expression"]
        properties:
          name:
            description: "Name for the corresponding output attribute."
            type: "string"
          expression:
            description: "
                The expression used to get the input value. Can be just a variable name ($myVar),
                a calculation ($myVar + 10) or a string interpolation (\"Test: {$myVar}!\")
                "
            type: "string"
          unit:
            description: "The unit of the variable. Only works if type is a number."
            type: "string"
          label:
            description: "A custom label to use in the frontend."
            type: "string"
          discrete:
            description: "
                Should be set to true if the value does not change continuously over time.
                "
            type: "boolean"
          acronym:
            description: "Acronym to show as value label in the frontend"
            type: "string"
            required: false
  }
  SimpleTruncatedMeanFilter: {
    title: "SimpleTruncatedMeanFilter config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      size:
        description: "Size of the sliding window of samples used for the calculation"
        type: "number"
        default: "5"
      output:
        type: "object"
        required: ["name", "expression"]
        properties:
          name:
            description: "Name for the corresponding output attribute."
            type: "string"
          expression:
            description: "
                The expression to use to get the input value. Can be just a variable name ($myVar),
                a calculation ($myVar + 10) or a string interpolation (\"Test: {$myVar}!\")
                "
            type: "string"
          unit:
            description: "The unit of the variable. Only works if type is a number."
            type: "string"
          label:
            description: "A custom label to use in the frontend."
            type: "string"
          discrete:
            description: "
                Should be set to true if the value does not change continuously over time.
                "
            type: "boolean"
          acronym:
            description: "Acronym to show as value label in the frontend"
            type: "string"
            required: false
  }
}