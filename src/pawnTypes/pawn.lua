local PawnType = require("pawnType")
local Point = require("point")

local Pawn = PawnType:new({icon = "Pa"})

--[[--
  Gets a list of valid moves for this pawn

  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function Pawn:getValidMoves(pawn)
  local board = pawn:getBoard()
  local moves = board:makeList()
  local space = pawn:getSpace()
  -- loop through all four directions
  for _, dir in ipairs(Point.ALL_DIRS) do
    -- can move if the space is empty
    local point = space + dir
    if board:isValid(point) and not board:isPawnAt(point) then
      moves:add(point)
    end
    -- can attack diagonally if not own color
    point = point + dir:rotateCW()
    if board:isValid(point) and board:isPawnAt(point) and not board:isColorAt(pawn, point) then
      moves:add(point)
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
  -- pawns move horizontals, attack on diagonal
  if offset.x == 0 or offset.y == 0 then
    -- not filled
    return not board:isPawnAt(target)
  else
    -- filled and not our color
    return board:isPawnAt(target) and not board:isColorAt(pawn, target)
  end
end

return Pawn
