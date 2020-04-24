local Board = require("board")
local Color = require("color")
local Network = require("network")
local Point = require("point")

--- Index of the X value node
local X_INDEX = 1
--- Index of the Y value node
local Y_INDEX = 2
--- Number of nodes before the pawn nodes
local GENERAL_NODES = 2
--- Number of nodes before the pawn nodes
local PAWN_OFFSET = GENERAL_NODES - 1
--- If within this distance, two points match and fallback to pawn logic
local MATCHING = 0.1

--- Index table, called Board for conveience of adding functions
local Agent = {}
Agent.__index = Agent

--[[--
  Returns the number of players based on the given network definition
  @return Number of players  for the given network
]]
local function getPawnCount(network)
  assert(Network.isA(network), "Argument #1 must be a network")
  -- two outputs represent the X and Y coords, remainder of the outputs is pawns
  local definition = network:getDefinition()
  return definition:getOutputs() - GENERAL_NODES
end

--[[--
  Returns the number of pawns supported by the network
  @return  Number of pawns for the given network
]]
local function getPlayerCount(network)
  assert(Network.isA(network), "Argument #1 must be a network")
  -- one set of pawns inputs for each player
  local definition = network:getDefinition()
  return math.floor(definition:getSize(1) / getPawnCount(network))
end

--[[--
  Constructor: creates a new agent

  @param data  Board data, should contain a network, and either a score or a board and a color
  @return  Board object
]]
function Agent:new(data)
  assert(Network.isA(data.network), "Data must contain a network")
  -- validate the network works for an agent
  local players = getPlayerCount(data.network)
  assert(players > 0, "Network must have at least 1 player")
  local pawns = getPawnCount(data.network)
  assert(pawns > 0 and pawns % 1 == 0, "Pawns must be an integer greater than 0")

  -- start creating agent
  local agent = {network = data.network, lastScores = 0}

  -- score is optional
  if data.scores ~= nil then
    assert(type(data.scores) == "table", "Scores must be a table")
    local agentScores = {}
    for i, score in ipairs(data.scores) do
      assert(type(score) == "number" and score >= 0, "Score must be a number")
      agentScores[i] = score
    end
    agent.scores = agentScores
  else
    agent.scores = {}
  end
  -- create final object
  return setmetatable(agent, self)
end

-- allow calling Agent() as an alternative to Agent:new()
setmetatable(Agent, {__call = Agent.new})

--[[--
  Creates a network defintion valid for an agent with the given hidden layers

  @param data     Table containing three named arguments
  @param pawns    Number of pawns for each team
  @param players  Number of teams total
  @param layers   Hidden layers in the network
  @return  Definition for a network valid for an agent
]]
function Agent.makeDefinition(data)
  assert(type(data) == "table", "Argument must be a table")
  local pawns = data.pawns or 4
  local players = data.players or 2
  local layers = data.layers or {}
  assert(type(pawns) == "number" and pawns > 0 and pawns % 1 == 0, "Pawns must be a positive integer")
  assert(type(players) == "number" and players > 0 and players % 1 == 0, "Players must be a positive integer")
  assert(type(layers) == "table", "Layers must be a table")

  -- start with X and Y value nodes
  local outputs = {"Clamp", "Clamp"}
  -- add decision node for each piece type
  for i = 1, pawns do
    table.insert(outputs, "Sig")
  end
  -- two inputs per team
  return Network.Definition(outputs, pawns * players, table.unpack(layers))
end

--[[--
  Checks if the given object is a Agent

  @param board   Object to check if its a Agent
  @return  true if its a agent
]]
function Agent.isA(agent)
  return getmetatable(agent) == Agent
end

----------------
-- Game logic --
----------------

--[[--
  Gets the number of pawns this agent supports
  @return  Number of pawns for this agent
]]
function Agent:getPawnCount()
  return getPawnCount(self.network)
end

--[[--
  Gets the number of pawns this agent supports
  @return  Number of pawns for this agent
]]
function Agent:getPlayerCount()
  return getPlayerCount(self.network)
end

--[[--
  Sets the board and color for the agent
  @param board  Agent board
  @param color  Agent color
]]
function Agent:setBoard(board, color)
  assert(Board.isA(board), "Argument #1 must be a Board")
  assert(Color.isA(color), "Argument #2 must be a Color")
  -- validate the board
  assert(board:getColorCount() == self:getPlayerCount(), "Board does not have the right number of players for this network")
  local pawns = self:getPawnCount()
  assert(board:getPawnCount(color) > 0, "Board must have at least one pawn in that color")
  for boardColor in board:colorIterator() do
    assert(board:getPawnCount(boardColor) == pawns, "Invalid pawn count for colors")
  end
  -- finally, set the property
  self.board = board
  self.color = color
end

--[[--
  Gets the input indexes for a pawn color

  @param inputs   Array to place indexes into
  @param board    Game board containing pieces
  @param color    Color to check on the board
  @param pawns    Pawn count in the board
]]
local function getPawnInputs(inputs, board, color, pawns)
  local size = board:getSize()
  for index = 1, pawns do
    local pawn = board:getPawn(color, index)
    assert(pawn ~= nil, "Pawn at index is nil")
    -- calling statically as space may be nil (off board)
    table.insert(inputs, Point.getIndex(pawn:getSpace(), size))
  end
end

--[[--
  Causes the agent to make a single move in the board

  @return board if we made a move, nil otherwise
]]
function Agent:makeMove()
  assert(self.board ~= nil and self.color ~= nil, "Must set agent board before getting moves")
  -- out pawns go first as inputs
  local inputs = {}
  local pawns = self:getPawnCount()
  getPawnInputs(inputs, self.board, self.color, pawns)
  -- then get all opponent pawns
  for opponent in board:colorIterator() do
    -- skip own pawn colors
    if opponent ~= self.color then
      getPawnInputs(inputs, self.board, opponent, pawns)
    end
  end
  assert(#inputs == self.network:getDefinition():getSize(1), "Invalid input count for network")

  -- get results
  local outputs = self.network:getOutput(inputs)
  local size = self.board:getSize()
  local x = outputs[X_INDEX] * size - 0.5
  local y = outputs[Y_INDEX] * size - 0.5

  -- find the best pawn to move
  local moveIndex = nil
  local moveSpace = nil
  local minDistance = size * 2
  for index = 1, pawns do
    local moves = self.board:getPawn(self.color, index):getValidMoves()
    local move = moves:findClosest(x, y)
    if move ~= nil then
      local distance = math.sqrt((x - move.x)^2 + (y - move.y)^2)
      -- if within MATCHING, choose the higher output node
      -- if outside MATCHING, choose the larget distance
      local diff = minDistance - distance
      local useMove = false
      if math.abs(diff) < MATCHING then
        if outputs[PAWN_OFFSET+moveIndex] < outputs[PAWN_OFFSET+index] then
          useMove = true
        end
      elseif diff > 0 then
        useMove = true
      end
      -- if either case, update the variables
      if useMove then
        moveIndex = index
        moveSpace = move
        minDistance = distance
      end
    end
  end
  -- make the move if we found one
  if moveIndex ~= nil and moveSpace ~= nil then
    self.board:getPawn(self.color, moveIndex):moveOrAddTo(moveSpace)
    return self.board
  end
  -- false means no move found
  return nil
end

--------------
-- Breeding --
--------------

-- Line with points is horizontal
local HORIZONTAL = 1
-- Line with points is vertical
local VERTICAL = 2
-- Line with points is diagonal from top left to bottom right
local PDIAGONAL = 3
-- Line with points is diagonal from bottom left to top right
local NDIAGONAL = 4

--[[--
  Gets the largest line count for the color

  @param board  Board instance
  @param color  Color to check for a line
  @return between 0 and 4 based on number of pieces in a line
  @return number of times lines of this size were seen
  @return point if line is of length 3, this returns the point that is missing
  @return direction of line if line has length of 3
]]
local function getLinedUp(board, color)
  -- Holds current highest number of pawns in a line
  local linedUp = 0
  local lineCount = 0
  -- holds missing point from a line of 3
  local missingPoint = nil
  -- holds direction of line (1: horizontal, 2: vertical, 3: positive diagonal, 4: negative diagonal)
  local lineDir = 0
  local maxCoord = board:getSize() - 1
  local directions = {Point(1, 0), Point(0, 1)}

  -- Loop through horizontal vs. vertical
  for i = 1,2 do
    -- Loop through rows or columns
    for sIndex = 0, maxCoord do
      -- Holds current number of pawns in line
      local check = 0
      -- Starting point of the line being checked
      local start = directions[3-i] * sIndex
      -- Used to save any missing points from a line
      local tempMissingPoint
      -- Loop through each point in the line
      for oIndex = 0, maxCoord do
        -- Find point based off of offset
        local point = start + directions[i] * oIndex
        -- Check if board has proper color at point in question
        if board:isColorAt(color, point) then
            check = check + 1
        else
            -- If not correct color, save point in case it is a line of three
            tempMissingPoint = point
        end
      end
      -- If current line has more than current max, replace it
      if check > linedUp then
          linedUp = check
          lineCount = 1
      elseif check == linedUp then
          lineCount = lineCount + 1
      end
      -- If line has 3, then save the point if needed for blocked score
      if check == maxCoord then
          missingPoint = tempMissingPoint
          -- For loop checks horizontal and then vertical, save line direction
          if i == 1 then
            lineDir = HORIZONTAL
          elseif i == 2 then
            lineDir = VERTICAL
          end
      end
    end
  end

  local diagonalStarts = {Point(0,0), Point(0, maxCoord)}
  local offset = {Point(1,1), Point(1,-1)}
  for i = 1, 2 do
    -- Holds current number of pawns in line
    local check = 0
    -- Starting point of the line being checked
    local tempMissingPoint
    -- Loop through each point in the line
    for oIndex = 0, maxCoord do
      local point = diagonalStarts[i] + offset[i] * oIndex
      -- Check if board has proper color at point in question
      if board:isColorAt(color, point) then
          check = check + 1
      else
          -- If not correct color, save point in case it is a line of three
          tempMissingPoint = point
      end
    end
    -- If current line has more than current max, replace it
    if check > linedUp then
        linedUp = check
        lineCount = 1
    elseif check == linedUp then
        lineCount = lineCount + 1
    end
    -- If line has 3, then save the point if needed for blocked score
    if check == maxCoord then
        missingPoint = tempMissingPoint
        -- For loop checks positive diagonal then negative diagonal
        -- 2 is to offset for horizontal and vertical
        if i == 1 then
          lineDir = PDIAGONAL
        elseif i == 2 then
          lineDir = NDIAGONAL
        end
    end
  end

  return linedUp, lineCount, missingPoint, lineDir
end

--[[--
  Gets the score based on how many pieces block our line

  @param board  Board instance
  @param color  Color being blocked
  @return score 0, 1, or 2 based on the board
]]
local function getBlockedScore(board, color)
  -- find our pieces, getLinedUp(board, color)
  local linedUp, _, point, dir = getLinedUp(board, color)
  -- line of 4 won
  local size = board:getSize()
  if linedUp == size then
    return 0
  end
  -- no line of 3 means its just okay
  local maxCoord = size - 1
  if linedUp < maxCoord then
    return 20
  end
  -- max score is two and gets reduced as better options are found
  local score = 20
  -- try to move each pawn to the point
  for i = 1, board:getPawnCount(color) do
    local pawn = board:getPawn(color, i)
    local tempScore = 0
    if pawn:getValidMoves():contains(point) then
      local pawnPosition = pawn:getSpace()
      -- if it can be captured by/moved to by a piece in the line, worth 1
      if pawnPosition ~= nil and
         ((dir == HORIZONTAL and pawnPosition.x == point.x) or
         (dir == VERTICAL and pawnPosition.y == point.y) or
         (dir == PDIAGONAL and pawnPosition.x == pawnPosition.y) or
         (dir == NDIAGONAL and pawnPosition.x == (maxCoord - pawnPosition.y))) then
        tempScore = 5
      else
        -- if it can be captured by/moved to a piece not in the line, worth 0
        tempScore = 0
      end
    else
      -- if it cannot be captured, worth 2
      tempScore = 20
    end
    score = math.min(score, tempScore)
  end
  return score
end

--[[--
  Gets a score based on how many lines we are blocking

  @param board  Board instance
  @param color  Color being blocked
]]
local function getBlockingScore(board, color)
  -- TODO: update to support more than 2 players
  return getBlockedScore(board, board:getOpponents(color)[1])
end

--[[--
  Scores this agent based on the result of their game

  @return  Score for this game between 0 and 1
]]
function Agent:calcScore(debug)
  -- if no board, do nothing
  if not self.board or not self.color then
    return nil
  end

  local line, count = getLinedUp(self.board, self.color)
  local blocked = getBlockedScore(self.board, self.color)
  local blocking = getBlockingScore(self.board, self.color)
  if debug then
    print("Lined up: " .. line)
    print("Line count: " .. count)
    print("Blocked: " .. blocked)
    print("Blocking: " .. blocking)
  end

  -- most important is having a line, multiples secondary
  -- next is our line not being blocked, then blocking the opponent
  -- minimal is a short game
  local score = (10 * (line*8 + count)) - (2*blocked) + blocking - (self.board:getMoveCount() / 2)
  for _, opponents in ipairs(board:getOpponents(self.color)) do
    -- worth more than blocking
    local opLine, opCount = getLinedUp(self.board, opponents)

    if debug then
      print("Opponent lined up: " .. opLine)
      print("Opponent lined count: " .. opCount)
    end
    score = score - (6 * (opLine*8 + opCount))
  end

  -- 0 is the min score
  return math.max(score, 0)
end

--[[--
  Saves a score to the agent
  @return  The saved score
]]
function Agent:saveScore()
  local score = self:calcScore()
  if score ~= nil then
    table.insert(self.scores, score)
  end
  return score
end

--[[--
  Gets the average score for all games for this agent
  @return  Agents average score
]]
function Agent:getAverageScore()
  if #self.scores == 0 then
    error("Agent has not been scored")
  end
  -- use cached score if valid
  if self.lastScores == #self.scores then
    return self.averageScore
  end

  -- sum all scores
  local sum = 0
  for _, score in ipairs(self.scores) do
    sum = sum + score
  end
  self.averageScore = sum / #self.scores
  self.lastScores = #self.scores
  return self.averageScore
end

--[[--
  Gets the percent of this agent that should be replaced with the other agent's DNA if they mate
]]
function Agent:getReplacement(mate)
  assert(Agent.isA(mate), "Mate must be an Agent")
  local selfScore = self:getAverageScore()
  local mateScore = mate:getAverageScore()
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
  return Agent:new{network = self.network:breed(mate.network, self:getReplacement(mate), mutation)}
end

--[[--
  Checks if the agent uses the given network definition
  @param defintion  Definition to check
  @return true if the definition is used
]]
function Agent:isDefinition(definition)
  return self.network.defintion == defintion
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
    self:saveScore()
  end

  -- score is optional, set only if provided
  local out = {"{weights=", self.network:getWeightString()}
  if #self.scores ~= 0 then
    table.insert(out, ",score={")
    table.insert(out, table.concat(self.scores, ","))
    table.insert(out, "}")
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
