local Color = require("color")
local PawnType = require("pawnType")
local Point = require("point")


--- List of directions a pawn can choose, though half are invalid for each pawn
local VALID_DIRECTIONS = {
  [0.000] = Point.UP,
  [0.125] = Point.UP + Point.RIGHT,
  [0.325] = Point.DOWN + Point.RIGHT,
  [0.500] = Point.DOWN,
  [0.625] = Point.DOWN + Point.LEFT,
  [0.875] = Point.UP + Point.LEFT
}
local Pawn = PawnType:new({icon = "Pa", directions = VALID_DIRECTIONS})

--[[--
  Gets a list of valid moves for this pawn

  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function Pawn:getValidMoves(pawn)
  local board = pawn:getBoard()
  local moves = board:makeList()
  local space = pawn:getSpace()
  local dir = pawn:getColor():getDir()

  -- can move if the space is empty
  local point = space + dir
  if board:isValid(point) and not board:isPawnAt(point) then
    moves:add(point)
  end
  -- can attack diagonally if not own color
  for angle = -90, 90, 180 do
    local diag = point + dir:rotate(angle)
    if board:isValid(diag) and board:isPawnAt(diag) and not board:isColorAt(pawn, diag) then
      moves:add(diag)
    end
  end

  return moves
end

--[[--
  Checks if a movement in the given direction is valid for this pawn

  @param pawn    Current pawn instance
  @param offset  Direction to check
  @return  True if the given direction is valid, false if invalid
]]
function Pawn:isDirectionValid(pawn, offset)
  -- space must be valid
  local target = pawn:getSpace() + offset
  local board = pawn:getBoard()
  if not board:isValid(target) then
    return false
  end

  -- pawn is limited to one direction
  local dir = pawn:getColor():getDir()
  if offset.y ~= pawn:getColor():getDir().y then
    return false
  end

  -- pawns move horizontals, attack on diagonal
  if offset.x == 0 then
    -- not filled
    return not board:isPawnAt(target)
  else
    -- filled and not our color
    return board:isPawnAt(target) and not board:isColorAt(pawn, target)
  end
end

return Pawn
