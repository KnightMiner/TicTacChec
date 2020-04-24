local Agent = require("agent")
local Board = require("board")
local Network = require("network")
local Color = require("color")

--- Path to generation save files
local SAVE_PATH = "../generations/"
local EXTENSION = ".gen"
-- Pawn types for the board
local TYPES = {
  require("pawnTypes/rook"),
  require("pawnTypes/pawn"),
  require("pawnTypes/bishop"),
  require("pawnTypes/knight"),
}

--- Index table, called Generation for conveience of adding functions
local Generation = {}
Generation.__index = Generation

-- ensure a seed is set
math.randomseed(os.time())

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
  assert(filename ~= Generation, "Generation.generate must be called statically")
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
  assert(filename ~= Generation, "Generation.read must be called statically")
  assert(type(filename) == "string", "Argument #1 must be a string")

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
      scores = agent.scores
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
  -- holds maximum score
  local curMax = 0
  -- holds best agent to be returned
  local bestAgent
  for _, agent in ipairs(self.agents) do
    local agentScore = agent:getAverageScore()
    if curMax < agentScore then
      curMax = agentScore
      bestAgent = agent
    end
  end
  return bestAgent
end

--[[--
  Gets a random agent from the generation, based on the agent scores

  @param self       Generation instance
  @param totalScore sum of all the agents scores
  @return a random agent
]]
local function getRandomAgent(self, totalScore)
  -- if every game scored badly, just randomly choose an agent
  if totalScore == 0 then
    return self.agents[math.random(#self.agents)]
  end

  -- Holds sum of agents as they are iterated through to find the randomly selected agent
  local compiledScore = 0

  -- Find score of random agent
  local targetScore = math.random() * totalScore
  -- Find which agents range has the targetScore
  for _, agent in ipairs(self.agents) do
    compiledScore = compiledScore + agent:getAverageScore()
    if compiledScore >= targetScore then
      return agent
    end
  end
  error("There was no random agent selected")
end

--[[--
  Gets the total score for this network

  @param self  Network to check
  @return  Total score for the network
]]
local function getTotalScore(self)
  local totalScore = 0
  for _, agent in ipairs(self.agents) do
    totalScore = totalScore + (agent:getAverageScore() or 0)
  end
  return totalScore
end

--[[--
  Returns the aev
]]
function Generation:getAverageScore()
  return getTotalScore(self) / #self.agents
end

--[[--
  Generates a child generation from this generation

  @param count           Number of children to produce
  @param mutationChance  Chance of mutation per weight when agents breed
  @param clones          Number of the best to clone from this generation
  @return New Generation instance
]]
function Generation:reproduce(count, mutationChance, clones)
  clones = clones or 0
  assert(type(count) == "number" and count > 0 and count % 2 == 0, "Count must be an even, positive integer")
  assert(type(mutationChance) == "number" and mutationChance >= 0 and mutationChance <= 1, "Mutation chance must be a number between 0 and 1")
  assert(type(clones) == "number" and clones >= 0, "Clones must be a non-negative integer")
  -- table to hold agents as they are created
  local newAgents = {}

  -- copy the best X clones into the next generation
  if clones > 0 then
    -- sort the list of agents to get the best
    local bestAgents = {}
    for i, agent in ipairs(self.agents) do bestAgents[i] = agent end
    table.sort(bestAgents, function(a, b)
      return a:getAverageScore() > b:getAverageScore()
    end)
    for i = 1, clones do
      table.insert(newAgents, bestAgents[i]:clone())
    end
  end

  -- Holds sum of all the agents scores
  local totalScore = getTotalScore(self)
  for i = 1, (count - clones) do
    -- get two random agents for breeding
    local agent1 = getRandomAgent(self, totalScore)
    local agent2 = getRandomAgent(self, totalScore)
    -- Breed the two agents and insert them into the table of new agents
    table.insert(newAgents, agent1:breed(agent2, mutationChance))
  end
  return Generation:new(self.definition, newAgents)
end

--[[--
  Creates a standard game board for a game

  @param size   Size of the board
  @return new board instance
]]
local function makeBoard(size)
  assert(type(size) == "number" and size > 0 and size % 1 == 0, "Size must be a positive integer")

  local board = Board(size)

  for _, type in ipairs(TYPES) do
    board:addPawn(Pawn(type, Color.WHITE))
    board:addPawn(Pawn(type, Color.BLACK))
  end
  return board
end

--[[--
  Plays a game with two agents

  @param agent1  First agent
  @param agent2  Second agent
  @param moves   Max number of moves to play
  @return winning agent
]]
local function playGame(agent1, agent2, moves)
  assert(Agent.isA(agent1), "Argument #1 must be an agent")
  assert(Agent.isA(agent2), "Argument #2 must be an agent")
  assert(type(moves) == "number" and moves > 0 and moves % 1 == 0, "Argument #3 must be a positive integer")
  local pawnCount = agent1:getPawnCount()
  assert(pawnCount == agent2:getPawnCount(), "Agents must have the same number of pawns")
  assert(agent1:getPlayerCount() == agent2:getPlayerCount(), "Agents must have the same number of players")

  -- create a new board for the agents to play
  local gameBoard = makeBoard(pawnCount)
  agent1:setBoard(gameBoard, Color.WHITE)
  agent2:setBoard(gameBoard, Color.BLACK)
  -- play for the given number of moves
  for currentMove = 1, moves do
    agent1:makeMove()
    -- Check for win and return if won
    if gameBoard:getWinner() ~= nil then
      return agent1
    end
    agent2:makeMove()
    -- Check for win and return if won
    if gameBoard:getWinner() ~= nil then
      return agent2
    end
  end
  -- If tie, return nil
  return nil
end

--[[--
  Plays all agents against each other to score children

  @param games  Number of games for each agent to play
  @param moves  Number of moves to play in each game
]]
function Generation:playGames(games, moves)
  assert(type(games) == "number" and games > 0 and games % 1 == 0, "Games must be a positive integer")
  assert(type(moves) == "number" and moves > 0 and moves % 1 == 0, "Moves must be a positive integer")

  -- TODO Multiple games will erase the previous score
  for i = 1, games do
    -- table to hold shuffled agents
    local shuffled = {}
    for _, agent in ipairs(self.agents) do
      -- Find random position
      local pos = math.random(1, #shuffled + 1)
      -- insert agent at random position
      table.insert(shuffled, pos, agent)
    end
    for i = 1, #shuffled, 2 do
      -- Take agents by twos and play a game
      playGame(shuffled[i], shuffled[i+1], moves)
      shuffled[i]:saveScore()
      shuffled[i+1]:saveScore()
    end
  end
end

--[[--
  Writes the generaton to a file

  @param filename  Name to write the generation into
  @return true if successfully writes to the file
]]
function Generation:write(filename)
  assert(self ~= Generation, "Cannot call write statically")
  assert(type(filename) == "string", "Filename must be a string")
  -- beginning of the file with the definition
  local output = {"return {\n  definition=", tostring(self.definition), ",\n  agents={\n"}
  -- write each agent
  for _, agent in ipairs(self.agents) do
    table.insert(output, "    ")
    table.insert(output, agent:save())
    table.insert(output, ",\n")
  end
  table.insert(output, "  }\n}")
  -- create the file
  local file = io.open(SAVE_PATH .. filename .. EXTENSION, "w")
  file:write(table.concat(output))
  file:close()
end

return Generation
