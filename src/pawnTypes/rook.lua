local PawnType = require("pawnType")
local Point = require("point")
local helpers = require("helpers")

local Rook = PawnType:new({icon = "Ro"})

--[[--
  Gets a list of valid moves for this pawn

  @param board  Board containing the pawn
  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function Rook:getValidMoves(board, pawn)
  local moves = board:makeList()
  -- loop through all four directions
  for _, dir in ipairs(Point.ALL_DIRS) do
    helpers.addLine(board, pawn, moves, dir)
  end

  return moves
end

return Rook
