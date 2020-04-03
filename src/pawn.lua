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
  Gets the type of this pawn

  @return pawn type
]]
function Pawn:getType()
  return self.type
end

--[[--
  Gets a list of valid moves for the pawn

  @return  table of valid moves for the pawn
]]
function Pawn:getValidMoves()
  assert(self.board ~= nil, "Pawn not added to a board")
  if self.space ~= nil then
    return self.type:getValidMoves(self.board, self)
  else
    return self.board:getEmptySpaces()
  end
end

--------------
-- Movement --
--------------

--[[--
  Gets the pawn's current space

  @param point  pawn's space or nil if off board
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
    assert(Point.isA(point), "Argument must be a point")
    assert(self.board:isValid(point), "Point not on board")
    assert(not self.board:isPawnAt(point), "Point must be empty")
  end

  -- if there is an existing pawn, remove it
  local current = self.board:getPawnAt(point)
  if current ~= nil then
    current.space = nil
  end

  -- move self
  self.space = point
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
  self.space = point
  self.board:checkWin(self)
  return self.board
end

--[[--
  Moves or adds the pawn to the point, based on whether its on the board

  @param point  Point to target
]]
function Pawn:moveOrAddTo(point)
  assert(self.board ~= nil, "Pawn not added to a board")
  assert(Point.isA(point), "Argument must be instance of point")

  -- nil space means not on board
  if self.space == nil then
    self:addTo(point)
  else
    self:moveTo(point)
  end
end

--[[--
  Gets a list of valid moves for the pawn

  @return  table of valid moves for the pawn
]]
function Pawn:__tostring()
  return Color.space(self.space, tostring(self.type), self.color)
end

return Pawn
