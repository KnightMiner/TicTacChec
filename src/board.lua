local Color = require("color")
local Point = require("point")
local PointList = require("pointList")
local Pawn = require("pawn")

--- Index table, called Board for conveience of adding functions
local Board = {}
Board.__index = Board

--[[--
  Constructor: creates a new board

  @param size  Board width and height
  @return  Board object
]]
function Board:new(size)
  assert(type(size) == "number", "Size must be a number")
  return setmetatable({
    size = size,
    pawns = {},
    teamPawns = {},
    moves = 0,
    colors = {},
    pawnSpaces = {}
  }, self)
end

-- allow calling Board() as an alternative to Board:new()
setmetatable(Board, {__call = Board.new})

--[[--
  Checks if the given object is a Board

  @param board   Object to check if its a Board
  @return  true if its a board
]]
function Board.isA(board)
  return getmetatable(board) == Board
end

----------------
-- Board size --
----------------

--[[--
  Gets the size of the board

  @return  Point representing board size
]]
function Board:getSize()
  return self.size
end

--[[--
  Checks if the given point is within the board

  @param point  Point
  @return true if the point is on the board
]]
function Board:isValid(point)
  assert(Point.isA(point), "Argument must be instance of point")
  return point.x >= 0 and point.x < self.size and point.y >= 0 and point.y < self.size
end

--[[--
  Creates a new point list from the given board size

  @return  new PointList
]]
function Board:makeList()
  return PointList(self.size)
end

-----------
-- Pawns --
-----------

--[[--
  Adds a pawn to the board

  @param pawn  Pawn to add to the board
]]
function Board:addPawn(pawn)
  assert(Pawn.isA(pawn), "Argument must be instance of pawn")
  local color = pawn:getColor()
  assert(color ~= nil, "Pawn color must be defined")
  if self.teamPawns[color] == nil then
    self.teamPawns[color] = {}
    table.insert(self.colors, color)
  end
  -- add pawn to both lists
  table.insert(self.pawns, pawn)
  table.insert(self.teamPawns[color], pawn)
  pawn.board = self
end

--[[--
  Returns if the board has a pawn at the given point

  @param point  Space to check
  @return  True if there is a pawn at the given space
]]
function Board:isPawnAt(point)
  assert(Point.isA(point), "Argument must be instance of point")
  -- return the first found pawn
  return self.pawnSpaces[point:getIndex(self.size)] and true
end

--[[--
  Gets a board pawn by index and color

  @param index  Pawn index, between 1 and number of pawn types
  @param color  Pawn color
  @return pawn at index and color
]]
function Board:getPawn(color, index)
  assert(Color.isA(color), "Argument #1 must be a color")
  assert(type(index) == "number", "Argument #2 must be a number")
  local pawns = self.teamPawns[color]
  if pawns == nil then
    return nil
  end
  return pawns[index]
end

--[[--
  Returns the pawn at the given space

  @param point  Pawn to find
  @return  Pawn at the given space
]]
function Board:getPawnAt(point)
  assert(Point.isA(point), "Argument must be instance of point")
  -- fetch from the space map
  return self.pawnSpaces[point:getIndex(self.size)]
end

--[[--
  Returns the pawn at the given space

  @param point  Color to check
  @param point  Pawn to find
  @return  Pawn at the given space
]]
function Board:isColorAt(color, point)
  assert(Point.isA(point), "Argument must be instance of point")
  local pawn = self:getPawnAt(point)
  return pawn ~= nil and pawn:isColor(color)
end

--[[--
  Gets a list of all opponents to the given color
  @param color  Color to check for opponents
  @return  Table of colors of opponents
]]
function Board:getOpponents(color)
  local colors = {}
  for _, boardColor in ipairs(self.colors) do
    if color ~= boardColor then
      table.insert(colors, boardColor)
    end
  end
  return colors
end

--[[--
  Gets an iterator for the list of colors in the board
  @return  Color iterator function with one return for the color
]]
function Board:colorIterator()
  local c = 0
  return function()
    c = c + 1
    return self.colors[c]
  end
end

--[[--
  Gets the number of colors in the current board, each color representing a team

  @return  Number of teams on the board
]]
function Board:getColorCount()
  return #self.colors
end

--[[--
  Gets the number of pawns for a given color

  @param color  Color to check
  @return
]]
function Board:getPawnCount(color)
  assert(Color.isA(color), "Argument must be instance of color")
  local pawns = self.teamPawns[color]
  return pawns and #pawns or 0
end

-------------------
-- Move counting --
-------------------

--[[--
  Call when making a move to increment the move count
]]
function Board:makeMove(pawn, from)
  assert(Pawn.isA(pawn), "Argument #1 must be a pawn")
  assert(from == nil or Point.isA(from), "Argument #2 must be a point")
  -- if no change, do nothing
  local to = pawn:getSpace()
  if from == to then
    return
  end

  -- increment moves made
  self.moves = self.moves + 1

  -- update pawn space on board
  if from ~= nil then
    self.pawnSpaces[from:getIndex(self.size)] = nil
  end
  if to ~= nil then
    self.pawnSpaces[to:getIndex(self.size)] = pawn
  end

  -- update message
  local name = tostring(pawn)
  -- removing
  if to == nil then
    self.message = string.format("Removed %s from %d,%d", name, from.x, from.y)
  -- placing
  elseif from == nil then
    self.message = string.format("Placed %s at %d,%d", name, to.x, to.y)
  else
    -- moving
    self.message = string.format("Moved %s from %d,%d to %d,%d", name, from.x, from.y, to.x, to.y)
  end
end

--[[--
  Gets the number of moves made on this board

  @return Number of moves made on this board
]]
function Board:getMoveCount()
  return self.moves
end

--------------------
-- Space checking --
--------------------

--[[--
  Gets a list of all empty spaces on the board

  @return  table of all empty spaces on the board
]]
function Board:getEmptySpaces()
  -- start with all spaces
  local spaces = self:makeList()
  for y = 0, self.size - 1 do
    for x = 0, self.size - 1 do
      spaces:add(Point(x,y))
    end
  end

  -- remove any pawn spaces
  for _, pawn in ipairs(self.pawns) do
    local space = pawn:getSpace()
    if space ~= nil then
      spaces:remove(space)
    end
  end
  return spaces
end

------------------
-- Win checking --
------------------

--[[--
  Checks a line for winning

  @param board      Board to check
  @param pawn       Pawn to check
  @param direction  Line direction
  @return  true if this pawn caused a victory in this direction, false if not
]]
function checkLine(board, pawn, direction)
  local space = pawn:getSpace()

  -- first, get the start of the line
  local start = space
  repeat
    start = start - direction
  until not board:isValid(start)
  start = start + direction

  -- next, iterate down direction, ensuring all pieces are our color
  local point = start
  -- diagonals may be shorter than the length, make sure they are valid
  local needed = board.size
  repeat
    -- if its not our color, no a win
    if not board:isColorAt(pawn, point) then
      return false
    end
    needed = needed - 1
    point = point + direction
  until not board:isValid(point)

  -- ensure we traversed enough spaces
  return needed == 0
end

--- Directions a win is possible
local WIN_DIRS = {Point.UP, Point.RIGHT, Point.UP+Point.RIGHT, Point.UP+Point.LEFT}

--[[--
  Checks if the given pawn caused the team to win

  @param board      Board to check
  @param pawn       Pawn to check
  @return  true if they won, false if no win
]]
local function checkWin(board, pawn)
  -- try each of the four directions for a win
  for _, dir in ipairs(WIN_DIRS) do
    if checkLine(board, pawn, dir) then
      return true
    end
  end
  return false
end

--[[--
  Checks if the given pawn caused the team to win and sets the board win flag
  @param pawn  Pawn that changed
]]
function Board:checkWin(pawn)
  if not self.winner and checkWin(self, pawn) then
    self.winner = pawn:getColor()
  end
end

--[[--
  Gets the winner of this game

  @return  Winner color, or nil if no winner
]]
function Board:getWinner()
  return self.winner
end

--[[--
  Prints the board to the screen
]]
function Board:__tostring()
  local out = {}

  -- header line
  local line = {}
  table.insert(line, Color.space(Point(-1,-1), "", Color.HEADER))
  for x = 0, self.size - 1 do
    table.insert(line, Color.space(Point(x,-1), x, Color.HEADER))
  end
  table.insert(out, table.concat(line, "|"))

  -- main board
  for y = 0, self.size - 1 do
    -- header column
    line = {}
    table.insert(line, Color.space(Point(-1,y), y, Color.HEADER))
    for x = 0, self.size - 1 do
      local point = Point(x,y)
      local pawn = self:getPawnAt(point)
      if pawn ~= nil then
        table.insert(line, tostring(pawn))
      else
        table.insert(line, Color.space(point))
      end
    end
    table.insert(out, table.concat(line, "|"))
  end

  -- add status message
  if self.message then
    table.insert(out, self.message)
  end
  -- add winner if won
  if self.winner then
    table.insert(out, "Winner: " .. self.winner:getName())
  end

  return table.concat(out, "\n")
end

return Board
