local Point = require("point")

-- Index table, called Pawn for conveience of adding functions
local PawnType = {}
PawnType.__index = PawnType

--- Default directions for a type: all 8 directions
PawnType.directions = {
  [0.000] = Point.UP,
  [0.125] = Point.UP + Point.RIGHT,
  [0.250] = Point.RIGHT,
  [0.325] = Point.DOWN + Point.RIGHT,
  [0.500] = Point.DOWN,
  [0.625] = Point.DOWN + Point.LEFT,
  [0.750] = Point.LEFT,
  [0.875] = Point.UP + Point.LEFT
}

--[[--
  Constructor: creates a new pawn type

  @param object  Pawn object data
  @return  Pawn object
]]
function PawnType:new(object)
  local object = object or {}
  setmetatable(object, self)
  -- clone metamethods to children
  self.__index = self
  self.__tostring = self.__tostring
  return object
end

--[[--
  Checks if the given object is a Board

  @param board   Object to check if its a Board
  @return  true if its a board
]]
function PawnType.isA(type)
  return getmetatable(type) == PawnType
end

--[[--
  Gets the display name of this pawn type based on the color
]]
function PawnType:__tostring()
  return self:getIcon()
end

--[[--
  Gets the display name of this pawn type based on the color
]]
function PawnType:getIcon()
  return self.icon or ""
end

--[[--
  Checks if a movement in the given direction is valid for this pawn

  @param pawn    Current pawn instance
  @param offset  Direction to check
  @return  True if the given direction is valid, false if invalid
]]
function PawnType:isDirectionValid(pawn, offset)
  local board = pawn:getBoard()
  local target = pawn:getSpace() + offset
  return board:isValid(target) and not board:isColorAt(pawn, target)
end

--[[--
  Gets a list of valid moves for this pawn

  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function PawnType:getValidMoves(pawn)
  return {}
end

--[[--
  Converts a direction and an amount from the neural network into a move for this pawn

  @param pawn   Current pawn instance
  @param angle      Angular percentage from 0 to 1
  @param amount     Distance to travel out of maximum from 0 to 1
  @return  Move made, or nil if no valid moves
]]
function PawnType:getMove(pawn, angle, amount)
  assert(type(angle) == "number" and angle >= 0 and angle <= 1, "Angle must be a number between 0 and 1")
  assert(type(amount) == "number" and amount >= 0 and amount <= 1,  "Amount must be a number between 0 and 1")

  -- first, sort the list of angles based on closest to the passed angle
  local minScore = 1 -- .5 is the max possible
  local direction = nil
  for dirAngle, point in pairs(self.directions) do
    -- get the shortest path to that point
    local score = math.abs(dirAngle - angle)
    score = math.min(score, 1 - score)
    -- if that path is shorter than our shortest and its valid, use it
    if score < minScore and pawn:isDirectionValid(point) then
      minScore = score
      direction = point
    end
  end
  -- no direction available means no valid moves
  if direction == nil then
    return nil
  end
  -- TODO: amount
  return pawn:getSpace() + direction
end

return PawnType
