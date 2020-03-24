local Color = require("color")
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

return Pawn
