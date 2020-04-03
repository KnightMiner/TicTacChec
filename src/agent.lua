local Board = require("board")
local Color = require("color")
local Network = require("network")

--- Index table, called Board for conveience of adding functions
local Agent = {}
Agent.__index = Agent

--[[--
  Constructor: creates a new agent

  @param data  Board data, should contain a network, and either a score or a board and a color
  @return  Board object
]]
function Agent:new(data)
  assert(Network.isA(data.network), "Data must contain a network")
  -- start creating agent
  local agent = {network = data.network}
  if data.score ~= nil then
    -- clear board and color if already scored
    assert(type(data.score) == "number" and data.score >= 0 and data.score <= 1, "Score must be a number")
    agent.score = data.score
  else
    -- must have board and color
    assert(Board.isA(data.board), "Data must have a Board")
    assert(Color.isA(data.color), "Data must have a Color")
    agent.board = data.board
    agent.color = data.color
  end
  -- create final object
  return setmetatable(agent, self)
end

-- allow calling Agent() as an alternative to Agent:new()
setmetatable(Agent, {__call = Agent.new})

--- Nodes needed for output for this agent to function
--- TODO: allow number of pawns to be passed as a parameter?
local OUTPUT_NODES = {
  "SigPos", "SigPos", "SigPos", "SigPos", -- pawns
  "SigPos", -- placing piece
  "Mod", "SigPos", -- direction, amount
  "SigPos", "SigPos" -- X, Y
}

--[[--
  Creates a network defintion valid for an agent with the given hidden layers

  @param ...  Hidden layers
  @return  Definition for a network valid for an agent
]]
function Agent.makeDefinition(...)
  -- have 8 inputs, one for each pawn space
  -- TODO: allow passing in pawn count?
  return Network.Definition(OUTPUT_NODES, 8, ...)
end

--[[--
  Checks if the given object is a Agent

  @param board   Object to check if its a Agent
  @return  true if its a agent
]]
function Agent.isA(agent)
  return getmetatable(agent) == Agent
end

--[[--
  Causes the agent to make a single move in the board
]]
function Agent:makeMove()
  assert(board ~= nil and color ~= nil, "Cannot play with an agent that is not fully initialized")
  -- TODO implement
end

--[[--
  Sets the board and color for the agent
  @param board  Agent board
  @param color  Agent color
]]
function Agent:setBoard(board, color)
  assert(Board.isA(board), "Argument #1 must be a Board")
  assert(Color.isA(color), "Argument #2 must be a Color")

  self.board = board
  self.color = color
end

--------------
-- Breeding --
--------------

--[[--
  Scores this agent based on the result of their game

  @return  Score for this game between 0 and 1
]]
function Agent:calcScore()
  -- TODO: calculate score

  return self.score
end

--[[--
  Gets the score for this agent from cache, or calculates it if missing

  @return  Agents cached score
]]
function Agent:getScore()
  if self.score == nil then
    self:calcScore()
  end

  return self.score
end

--[[--
  Gets the percent of this agent that should be replaced with the other agent's DNA if they mate
]]
function Agent:getReplacement(mate)
  assert(Agent.isA(mate), "Mate must be an Agent")
  local selfScore = self:getScore()
  local mateScore = mate:getScore()
  return mateScore / (selfScore + mateScore)
end

--[[--
  Breeds two agents together, returning the Network child
  @param mate      Agent to breed with this agent
  @param mutation  Mutation chance during breeding
]]
function Agent:breed(mate, mutation)
  assert(Agent.isA(mate), "Argument #1 must be an Agent")
  assert(type(mutation) == "number" and mutation >= 0 and mutation <= 1, "Argument #2 must be a number between 0 and 1")
  return self.network:breed(mate.network, self:getReplacement(mate), mutation)
end

--[[--
  Saves the agent to a string

  @param calcScore  if true, gets the score before saving
  @return  string representing the agent
]]
function Agent:save(calcScore)
  assert(type(calcScore) == "boolean", "Argument #1 must be a boolean")

  -- calc the score if requested
  if calcScore then
    self:calcScore()
  end

  -- score is optional, set only if provided
  local out = {"Agent{weights=", network:getWeightString()}
  if self.score ~= nil then
    table.insert(out, ",score=")
    table.insert(out, self.score)
  end
  table.insert(out, "}")
  return table.concat(out);
end

--[[--
  Converts an agent to a string to save in a data file

  @return Agent as a string
]]
function Agent:__tostring()
  return self:save(false)
end

return Agent
