local PawnType = require("pawnType")
local Point = require("point")

local Pawn = PawnType:new({icon = "Pa"})

--[[--
  Gets a list of valid moves for this pawn

  @param board  Board containing the pawn
  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function Pawn:getValidMoves(board, pawn)
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

return Pawn
