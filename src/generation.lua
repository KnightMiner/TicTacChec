local Agent = require("agent")
local Board = require("board")
local Network = require("network")

--- Path to generation save files
local SAVE_PATH = "../generations/"
local EXTENSION = ".gen"

--- Index table, called Generation for conveience of adding functions
local Generation = {}
Generation.__index = Generation

--[[--
  Constructor: creates a new generation. Localized rather than global to restrict

  @param data  Generation data, should contain a network, and either a score or a board and a color
  @return  Generation object
]]
function Generation:new(definition, agents)
  assert(Network.Definition.isA(definition), "Expected network defintion")
  assert(type(agents) == "table", "Agents must be an array")
  assert(#agents % 2 == 0, "Must have an even number of agents")
  local generation = {definition = definition}
  generation.agents = {}
  for _, agent in ipairs(agents) do
    assert(Agent.isA(agent), "Array must contain agents")
    assert(agent:isDefinition(defintion), "Mismatched network definition for agent")
    table.insert(generation.agents, agent)
  end

  -- create final object
  return setmetatable(generation, self)
end

--[[--
  Create a generation by generating networks

  @param definition  Network definition for agents in generation
  @param count       Number of agents in the generation
  @return  Generation instance
]]
function Generation.generate(definition, count)
  assert(Network.Definition.isA(definition), "Invalid network definition")
  assert(type(count) == "number" and count % 2 == 0, "Count must be an even integer")
  -- generate a new agent for the count
  local agents = {}
  for i = 1, count do
    agents[i] = Agent{network = definition:generate()}
  end
  -- create the generation object
  return Generation:new(definition, agents)
end

--[[--
  Checks if the given object is a Generation

  @param gen   Object to check if its a Generation
  @return  true if its a Generation
]]
function Generation.isA(gen)
  return getmetatable(gen) == Generation
end

--[[--
  Reads a generation from a file

  @param filename  Name of the generation file
  @return New generation instance
]]
function Generation.read(filename)
  -- load the file
  _G.Network = Network
  local data = dofile(SAVE_PATH .. filename .. EXTENSION)

  -- parse lua contents
  local def = data.definition
  assert(Network.Definition.isA(def), "Invalid file, missing network definition")
  assert(type(data.agents) == "table", "Invalid file, missing agents")
  -- parse agents
  local agents = {}
  for i, agent in ipairs(data.agents) do
    assert(type(agent.weights) == "table", "Invalid agent, missing weights")
    assert(agent.score == nil or type(agent.score) == "number", "Invalid agent, score must be a number")
    agents[i] = Agent{
      network = def:build(agent.weights),
      score = agent.score
    }
  end
  -- finally, create the generation
  return Generation:new(def, agents)
end

------------------------
-- Instance functions --
------------------------

--[[--
  Gets the best agent in a generation

  @return agent with the highest score
]]
function Generation:getBestAgent()
  -- TODO
end

--[[--
  Gets a random agent from the generation, based on the agent scores

  @param self  Generation instance
  @return a random agent
]]
local function getRandomAgent(self)
  -- TODO
  -- consider a second parameter to cache score relationship
end

--[[--
  Generates a child generation from this generation

  @param count           Number of children to produce
  @param mutationChance  Chance of mutation per weight when agents breed
  @return New Generation instance
]]
function Generation:reproduce(count, mutationChance)
  assert(type(count) == "number" and count % 2 == 0, "Count must be an even integer")
  -- TODO
  -- ...
  -- return Generation:new(agents)
end

--[[--
  Creates a standard game board for a game
]]
local function makeBoard()
end

--[[--
  Plays a game with two agents

  @param agent1  First agent
  @param agent2  Second agent
  @param moves   Max number of moves to play
  @return winning agent
]]
local function playGame(agent1, agent2, moves)
  -- TODO
end

--[[--
  Plays all agents against each other to score children

  @param games  Number of games for each agent to play
  @param moves  Number of moves to play in each game
]]
function Generation:score(games, moves)
  -- TODO
end

--[[--
  Writes the generaton to a file

  @param filename  Name to write the generation into
  @return true if successfully writes to the file
]]
function Generation:write(filename)
  assert(self ~= Generation, "Cannot call write statically")
  local output = {"return {\n  definition=", tostring(self.definition), ",\n  agents={\n"}
  for _, agent in ipairs(self.agents) do
    table.insert(output, "    ")
    table.insert(output, agent:save(true))
    table.insert(output, ",\n")
  end
  table.insert(output, "  }\n}")

  -- create the file
  local file = io.open(SAVE_PATH .. filename .. EXTENSION, "w")
  file:write(table.concat(output))
  file:close()
end

return Generation
