local Color = require("color")
local Point = require("point")
local PawnType = require("pawnType")
local helpers = require("helpers")

--- Pawn class
local Pawn = {}
Pawn.__index = Pawn

--[[--
  Creates a new pawn from the given parameters

  @param type  PawnType
  @param color Pawn color
  @return  new pawn instance
]]
function Pawn:new(type, color)
  assert(PawnType.isA(type), "Invalid pawn type")
  assert(Color.isA(color), "Invalid color")
  return setmetatable({
    type = type,
    color = color,
    space = nil,
    board = board
  }, self)
end

-- allow calling Pawn() as an alternative to Pawn:new()
setmetatable(Pawn, {__call = Pawn.new})

--[[--
  Checks if the given object is a Pawn

  @param pawn   Object to check if its a Pawn
  @return  true if its a Pawn
]]
function Pawn.isA(pawn)
  return getmetatable(pawn) == Pawn
end

-----------------
-- Color logic --
-----------------

--[[--
  Gets the color of this pawn

  @return pawn color
]]
function Pawn:getColor()
  return self.color
end

--[[--
  Checks if the pawn color is the given color

  @param color  Color to check or pawn to compare colors
  @return true if the colors match
]]
function Pawn:isColor(color)
  -- if given a pawn, check if the color matches
  if Pawn.isA(color) then
    return self:isColor(color:getColor())
  end
  -- color parameter
  assert(Color.isA(color), "Argument must be a color or a pawn")
  return self.color == color
end

---------------------
-- Pawn type logic --
---------------------

--[[--
  Gets the pawn's current board
  @return  Board containing this pawn
]]
function Pawn:getBoard()
  return self.board
end

--[[--
  Gets the type of this pawn

  @return pawn type
]]
function Pawn:getType()
  return self.type
end

--[[--
  Checks if a movement in the given direction is valid for this pawn

  @param offset  Direction to check
  @return  True if the given direction is valid, false if invalid
]]
function Pawn:isDirectionValid(offset)
  assert(Point.isA(offset), "Parameter must be a point")
  assert(self.board ~= nil, "Pawn not added to a board")
  assert(self.space ~= nil, "Pawn not placed on the board")
  return self.type:isDirectionValid(self, offset)
end

--[[--
  Gets a list of valid moves for the pawn

  @return  table of valid moves for the pawn
]]
function Pawn:getValidMoves()
  assert(self.board ~= nil, "Pawn not added to a board")
  if self.space ~= nil then
    return self.type:getValidMoves(self)
  else
    return self.board:getEmptySpaces()
  end
end

--------------
-- Movement --
--------------

--[[--
  Gets the pawn's current space
  @return  pawn's space or nil if off board
]]
function Pawn:getSpace()
  return self.space
end

--[[--
  Sets the pawn's space to the given point

  @param point  new space or nil
]]
function Pawn:setSpace(point)
  assert(self.board ~= nil, "Pawn not added to a board")
  if point ~= nil then
    assert(point == nil or Point.isA(point), "Argument must be a point")
    assert(self.board:isValid(point), "Point not on board")
    assert(not self.board:isPawnAt(point), "Point must be empty")
  end

  -- if there is an existing pawn, remove it
  local current = self.board:getPawnAt(point)
  if current ~= nil then
    current.space = nil
  end

  -- move self
  local old = self.space
  self.space = point
  self.board:makeMove(self, old)
end

--[[--
  Adds the pawn to the board at the existing space

  @param point  Point to add the pawn
]]
function Pawn:addTo(point)
  assert(self.board ~= nil, "Pawn not added to a board")
  assert(self.space == nil, "Pawn already on the board")
  assert(Point.isA(point), "Argument must be instance of point")
  assert(self.board:isValid(point), "Point not on board")

  -- ensure space is empty
  if self.board:isPawnAt(point) then
    error("Space already occupied")
  end
  -- move the pawn and check win
  self.space = point
  self.board:makeMove(self)
  self.board:checkWin(self)
  return self.board
end

--[[--
  Moves the pawn to the given space, capturing the piece there if present

  @param point  Point to move the pawn
]]
function Pawn:moveTo(point)
  assert(self.board ~= nil, "Pawn not added to a board")
  assert(self.space ~= nil, "Pawn not on the board")
  assert(Point.isA(point), "Argument must be instance of point")
  assert(self.board:isValid(point), "Point not on board")
  assert(self:getValidMoves():contains(point), "Invalid move")

  -- if there is an existing pawn, remove it
  local current = self.board:getPawnAt(point)
  if current ~= nil then
    current.space = nil
  end
  -- move the pawn and check win
  local oldSpace = self.space
  self.space = point
  self.board:makeMove(self, oldSpace)
  self.board:checkWin(self)
  return self.board
end

--[[--
  Moves the pawn the given direction and amount

  @param direction  Angular percentage from 0 to 1
  @param amount     Distance to travel out of maximum from 0 to 1
  @return  true if a move is made, or false otherwise
]]
function Pawn:moveBy(direction, amount)
  assert(type(direction) == "number" and direction >= 0 and direction <= 1, "Argument #1 must be a number between 0 and 1")
  assert(type(amount) == "number" and amount >= 0 and amount <= 1, "Argument #1 must be a number between 0 and 1")

  -- ensure a move exists
  local target = self.type:getMove(self, direction, amount)
  if target == nil then
    return nil
  end

  -- make move if valid
  self:moveTo(target)
  return board
end

--[[--
  Moves or adds the pawn to the point, based on whether its on the board

  @param point  Point to target
]]
function Pawn:moveOrAddTo(point, y)
  assert(self.board ~= nil, "Pawn not added to a board")
  if type(point) == "number" and type(y) == "number" then
    point = Point(point, y)
  end
  assert(Point.isA(point), "Argument must be instance of point")

  -- nil space means not on board
  if self.space == nil then
    self:addTo(point)
  else
    self:moveTo(point)
  end
  return board
end

--- Make calling a pawn instance move or add it to the board, for debug
Pawn.__call = Pawn.moveOrAddTo

--[[--
  Gets a list of valid moves for the pawn

  @return  table of valid moves for the pawn
]]
function Pawn:__tostring()
  return Color.space(self.space, tostring(self.type), self.color)
end

return Pawn
