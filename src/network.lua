local Node = require("node")

--- Final class export

-------------------
-- Network logic --
-------------------

local Network = {}
Network.__index = Network

-- no constructor, it will be handled by Defintion

--[[--
  Checks if the given object is a network

  @param network  Object to check
  @return  true if the object is a network
]]
function Network.isA(network)
  return getmetatable(network) == Network
end

--[[--
  Gets the value for a layer of nodes and the given input
  @param layer  Layer of nodes
  @param input  Input numbers
]]
local function getLayerValues(layer, input)
  local output = {}
  for i, node in ipairs(layer) do
    output[i] = node:getOutput(input)
  end
  return output
end

--[[--
  Gets the output of the given network

  @param input  Input number table
  @return  Table of output numbers
]]
function Network:getOutput(input)
  assert(type(input) == "table", "Input must be a table of numbers")
  for _, v in ipairs(input) do
    assert(type(v) == "number", "Input must be a table of numbers")
  end

  -- simply apply each layer to the output
  local output = input
  for _, layer in ipairs(self.layers) do
    output = getLayerValues(layer, output)
  end
  return output
end

--[[--
  Gets all the weights as a string for writing to a file

  @return  Weights as a lua table string
]]
function Network:getWeightString()
  local out = {}
  for _, layer in ipairs(self.weights) do
    local nodes = {}
    for _, node in ipairs(layer) do
      table.insert(nodes, string.format("{%s}", table.concat(node, ",")))
    end
    table.insert(out, string.format("{%s}", table.concat(nodes, ",")))
  end
  return string.format("{%s}", table.concat(out, ","))
end

--[[--
  Breeds two networks together and returns the offspring

  @param mate         Network to mate with this network
  @param replacement  Percent chance to replace DNA from this network with the other network
  @param mutation     Percent chance to mutate the DNA
  @return  New bred network
]]
function Network:breed(mate, replacement, mutation)
  assert(Network.isA(mate), "Argument #1 must be a Network")
  assert(type(replacement) == "number" and replacement >= 0 and replacement <= 1, "Argument #2 must be a number between 0 and 1")
  assert(type(mutation) == "number" and mutation >= 0 and mutation <= 1, "Argument #3 must be a number between 0 and 1")
  assert(self.defintion == mate.definition, "Networks are not compatible")

  -- TODO implement
end

--[[--
  Gets a string to describe this network

  @return string
]]
function Network:__tostring()
  return string.format("Network: %s", self:getWeightString())
end

------------------------
-- Network definition --
------------------------

local Definition = {}
Definition.__index = Definition
Network.Definition = Definition

--[[--
  Creates the definition of a network

  @param outputs  Array of output node types. See Node.lua for options
  @param ...      Sizes for inputs
]]
function Definition:new(outputs, ...)
  assert(type(outputs) == "table", "Outputs must be a table of strings")
  for _, v in ipairs(outputs) do
    assert(type(v) == "string", "Outputs must be a table of strings")
  end
  -- validate layers
  local layers = {...}
  assert(#layers > 0, "Must have at least one layer")
  for _, v in ipairs(layers) do
    assert(type(v) == "number", "Layers must be numbers")
  end

  -- create the network definition
  return setmetatable({
    layers = layers,
    outputs = outputs
  }, self)
end

-- allow calling Network() as an alternative to Network:new()
setmetatable(Definition, {__call = Definition.new})

--[[--
  Checks if the given object is a network definition

  @param definition  Object to check
  @return  true if the object is a network definition
]]
function Definition.isA(definition)
  return getmetatable(definition) == Definition
end

--[[--
  Converts the given network into a string

  @return  String representation of this network
]]
function Definition:__tostring()
  return string.format("Network.Definition({'%s'},%s)",
    table.concat(self.outputs, "','"),
    table.concat(self.layers, ",")
  )
end

--[[--
  Gets the size of the given layer

  @param index  Index to check size
  @return  Layer size
]]
function Definition:getSize(index)
  assert(type(index) == "number" and index > 0, "Index must be a positive number")
  -- if the layer index is one above the array, they want the output layer
  if index == #self.layers + 1 then
    return #self.outputs
  end
  -- fetch from the layers array
  local layer = self.layers[index]
  assert(layer ~= nil, "Layer does not exist")
  return layer
end

--[[--
  Creates a network from this definition

  @param weights  Weights for each layer of the network
  @return  Working network
]]
function Definition:build(weights)
  assert(type(weights) == "table", "Weights must be a table")
  -- one table per layer
  -- layers have one value per node
  -- nodes have one weight per input
  -- should have one parameter per layer
  if #weights ~= #self.layers then
    error("Wrong number of layers in input parameters, should have ".. #self.layers)
  end
  -- validate all layers
  for l, layer in ipairs(weights) do
    assert(type(layer) == "table", "Layers must be table of node weights")
    -- must have one value per node expected in the layer
    local layerSize = self:getSize(l + 1)
    if #layer ~= layerSize then
      error("Layer " .. l .. " must have " .. layerSize .. " nodes")
    end
    -- ensure noes have the right amount of weights
    local inputSize = self:getSize(l)
    for _, node in ipairs(layer) do
      assert(type(node) == "table", "Nodes must be a table of input weights")
      -- ensure the proper number of weights in this node
      if #node ~= inputSize then
        error("Layer " .. l .. " must have " .. inputSize .. " weights")
      end
      -- ensure weights are numbers
      for _, weight in ipairs(node) do
        assert(type(weight) == "number", "Weights must be numbers")
      end
    end
  end

  -- finally create the network
  local network = {
    definition = self,
    weights = weights,
    layers = {}
  }
  -- add nodes for hidden layers, hold off on the last one though
  -- i is the index of the input, i+1 is the index of our current layer size
  for i = 1, #self.layers - 1 do
    -- build nodes for the layer
    local layer = {}
    local layerWeights = weights[i]
    for n = 1, self.layers[i+1] do
      layer[n] = Node.Sig(layerWeights[n])
    end
    -- add the layer to the network
    network.layers[i] = layer
  end

  -- output uses special node types
  local layer = {}
  local outputWeights = weights[#self.layers]
  for n, type in ipairs(self.outputs) do
    layer[n] = Node[type](outputWeights[n])
  end
  network.layers[#self.layers] = layer

  -- set metatable and return the network
  return setmetatable(network, Network)
end

--[[--
  Generates a network based on this definition with random weights

  @return new Network with random weights
]]
function Definition:generate()
  -- TODO implement
end


--[[--
  Logic to compare two network definitions

  @param left   Possible left network
  @param Right  Possible right network
  @return  true if they are equal
]]
function Definition.__eq(left, right)
  -- TODO: comparison
  return false
  --return Definition.isA(left) and Definition.isA(right)
end

return Network
