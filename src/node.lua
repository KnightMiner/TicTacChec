--- Final class export and common node type
local Node = {}
Node.__index = Node

--[[--
  Constructor: creates a new node from the set of weights

  @param name        Name of this node type
  @param activation  Activation function for this node type
  @param weights     Table of weights for the function
]]
function Node:new(name, activation, weights)
  assert(type(weights) == "table", "Weights must be a table")
  assert(#weights > 0, "Must have at least one input")
  assert(type(activation) == "function", "Activation must be a function")
  assert(type(name) == "string", "Name must be a string")

  -- copy the weights table to a local table, and check types
  local object = {
    activation = activation,
    name = name
  }
  for k, v in ipairs(weights) do
    assert(type(v) == "number", "Weights must all be numbers")
    object[k] = v
  end

  -- return object
  return setmetatable(object, self)
end

--- Function to return the input
local function identity(input) return input end

-- Calling node direction gives identity node
setmetatable(Node, {
  --[[--
    Creates a new node with identity activation
    @param weights  List of weights
    @return  Identity node
  ]]
  __call = function(self, weights)
    return Node:new("Node", identity, weights)
  end
})

----------------
-- Node logic --
----------------

--[[--
  Gets the number of inputs required to use this node

  @return  number of inputs needed for Node:getValue()
]]
function Node:getSize()
  return #self
end

--[[--
  Gets the value of this node for the given set of inputs

  @param inputs  Inputs array
  @return  value of the node for the set of inputs
]]
function Node:getOutput(inputs)
  assert(type(inputs) == "table", "Inputs must be a table")
  local size = self:getSize()
  assert(#inputs == size, "Inputs must be length of " .. size)

  -- perform the weighted sum
  local sum = 0
  for i = 1, size do
    assert(type(inputs[i]) == "number", "Inputs must all be numbers")
    sum = sum + inputs[i] * self[i]
  end
  -- run the activation function
  return self.activation(sum)
end

--[[--
  Creates a string representation of this node

  @return string representing this node
]]
function Node:__tostring()
  return string.format("%s({%s})", self.name, table.concat(self, ","))
end

------------------------
-- Special node types --
------------------------

--- Map of valid node types
local validTypes = {}

--[[--
  Checks if the given node type is valid
]]
function Node.isTypeValid(name)
  return validTypes[name] ~= nil
end

--[[--
  Macro function to generate constructors for node types

  @param name        Node type name
  @param activation  Activation function for this type
]]
local function addNode(name, activation)
  local fullName = "Node." .. name
  Node[name] = function(weights)
    return Node:new(fullName, activation, weights)
  end
  validTypes[name] = true
end
--- remake identity as a node child for conveience
addNode("I", identity)

--- Clamps the input to between 0 and 1
local function clamp(input)
  if input > 1 then
    return 1.0
  elseif input < 0 then
    return 0.0
  end
  return input
end
addNode("Clamp", clamp)

--- Applies modulo to the input, between 0 and 1
local function mod(input)
  return input % 1
end
addNode("Mod", mod)

--- Sigmoid function used for hidden layers
local function sig(input)
  return input / (1 + math.abs(input))
end
addNode("Sig", sig)

--- Sigmoid function to clamp values between 0 and 1
local function sigPos(input)
  return (sig(input) + 1) / 2
end
addNode("SigPos", sig)

return Node
