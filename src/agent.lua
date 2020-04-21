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
  -- network required
  assert(Network.isA(data.network), "Data must contain a network")
  -- start creating agent
  local agent = {network = data.network}

  -- score is optional
  if data.score ~= nil then
    assert(type(data.score) == "number" and data.score >= 0 and data.score <= 1, "Score must be a number")
    agent.score = data.score
  end
  -- create final object
  return setmetatable(agent, self)
end

-- allow calling Agent() as an alternative to Agent:new()
setmetatable(Agent, {__call = Agent.new})

--[[--
  Creates a network defintion valid for an agent with the given hidden layers

  @param pawns  Number of pawns for each team
  @param ...    Hidden layers
  @return  Definition for a network valid for an agent
]]
function Agent.makeDefinition(pawns, ...)
  assert(type(pawns) == "number" and pawns > 0 and pawns % 1 == 0, "Pawns must be a positive integer")

  -- start with X and Y value nodes
  local outputs = {"Clamp", "Clamp"}
  -- add decision node for each piece type
  for i = 1, pawns do
    table.insert(outputs, "Sig")
  end
  -- two inputs per team
  return Network.Definition(outputs, pawns * 2, ...)
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
  Gets the largest line count for the color

  @param board  Board instance
  @param color  Color to check for a line
  @return between 0 and 4 based on number of pieces in a line
  @return point if line is of length 3, this returns the point that is missing
  @return direction of line if line has length of 3
]]
local function getLinedUp(board, color)
  -- Holds current highest number of pawns in a line
  local linedUp = 0
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
      end
      -- If line has 3, then save the point if needed for blocked score
      if check == 3 then
          missingPoint = tempMissingPoint
          -- For loop checks horizontal and then vertical, save index for line Direction
          lineDir = i
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
    end
    -- If line has 3, then save the point if needed for blocked score
    if check == 3 then
        missingPoint = tempMissingPoint
        -- For loop checks positive diagonal then negative diagonal
        -- 2 is to offset for horizontal and vertical
        lineDir = 2 + i
    end
  end
  return linedUp, missingPoint, lineDir
end

--[[--
  Gets the score based on how many pieces block our line

  @param board  Board instance
  @param color  Color being blocked
  @return score 0, 1, or 2 based on the board
]]
local function getBlockedScore(board, color)
  -- find our pieces, getLinedUp(board, color)
  local linedUp, point, dir = getLinedUp(board, color)
  -- max score is two and gets reduced as better options are found
  local score = 2
  -- 0 if no lines of 3
  if linedUp < 3 then
    return 0
  end
  -- 0 if no pawn at the point
  if not board:isPawnAt(point) then
    return 0
  end
  for i = 1, board:getPawnCount(color) do
    local pawn = board:getPawn(color, i)
    local tempScore = 0
    if pawn:getValidMoves():contains(point) then
      local pawnPosition = pawn:getSpace()
      if (dir == 1 and pawnPosition.x == point.x) or
         (dir == 2 and pawnPosition.y == point.y) or
         (dir == 3 and pawnPosition.x == pawnPosition.y) or
         (dir == 4 and pawnPosition.x == (3 - pawnPosition.y)) then
           -- if it can be captured by a piece in the line, worth 1
        tempScore = 1
      else
        -- if it can be captured by a piece not in the line, worth 0
        tempScore = 0
      end
    else
      -- if it cannot be captured, worth 2
      tempScore = 2
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
function Agent:calcScore()
  -- if no board, do nothing
  if not self.board or not self.color then
    return nil
  end

  -- TODO: weights
  self.score
    = getLinedUp(self.board, self.color)
    + getBlockingScore(self.board, self.color)
    - getBlockedScore(self.board, self.color)
    - self.board:getMoveCount()

  for _, opponents in ipairs(board:getOpponents(self.color)) do
    -- TODO: weight
    self.score = self.score - getLinedUp(self.board, opponents)
  end

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
    self:calcScore()
  end

  -- score is optional, set only if provided
  local out = {"{weights=", self.network:getWeightString()}
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
