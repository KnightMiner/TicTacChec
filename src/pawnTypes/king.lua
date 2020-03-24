local PawnType = require("pawnType")
local Point = require("point")
local helpers = require("helpers")

local King = PawnType:new({icon = "Ki"})

--[[--
  Gets a list of valid moves for this pawn

  @param board  Board containing the pawn
  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function King:getValidMoves(board, pawn)
  local moves = board:makeList()
  local space = pawn:getSpace()
  -- loop through all four directions
  for _, dir in ipairs(Point.ALL_DIRS) do
    -- run normal, and rotate once for diagonal
    helpers.addPoint(board, pawn, moves, space + dir)
    helpers.addPoint(board, pawn, moves, space + dir + dir:rotateCW())
  end

  return moves
end

return King
