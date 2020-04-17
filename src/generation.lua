local Board = require("board")
local Color = require("color")
local Network = require("network")

--- Index table, called Generation for conveience of adding functions
local Generation = {}
Generation.__index = Generation

--[[--
  Constructor: creates a new generation

  @param data  Board data, should contain a network, and either a score or a board and a color
  @return  Board object
]]
function Generation:new(agents)
  assert(type(agents) == "table", "Agents must be an array")
  assert(#agents % 2 == 0, "Must have an even number of agents")
  local generation = {}
  generation.agents = {}
  for _, agent in ipairs(agents) do
    assert(Agent.isA(agent), "Array must contain agents")
    table.insert(generation.agents, agent)
  end

  -- create final object
  return setmetatable(generation, self)
end

-- allow calling Generation() as an alternative to Generation:new()
setmetatable(Generation, {__call = Generation.new})

--[[--
  Checks if the given object is a Generation

  @param gen   Object to check if its a Generation
  @return  true if its a Generation
]]
function Generation.isA(gen)
  return getmetatable(gen) == Generation
end

--[[--
  Create a generation by generating networks

  @param definition  Network definition for agents in generation
  @param count       Number of agents in the generation
  @return  Generation instance
]]
function Generation.generate(definition, count)
  assert(type(count) == "number" and count % 2 == 0, "Count must be an even integer")
  -- TODO
  -- ...
  -- return Generation:new(agents)
end

--[[--
  Reads a generation from a file

  @param filename  Name of the generation file
  @return New generation instance
]]
function Generation.read(filename)
  -- TODO
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
  -- TODO
end

return Generation
