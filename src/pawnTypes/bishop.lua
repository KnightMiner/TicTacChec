local PawnType = require("pawnType")
local Point = require("point")
local helpers = require("helpers")

local Bishop = PawnType:new({icon = "Bi"})

--[[--
  Gets a list of valid moves for this pawn

  @param board  Board containing the pawn
  @param pawn   Current pawn instance
  @return  PointList of valid spaces this pawn can move to
]]
function Bishop:getValidMoves(board, pawn)
  local moves = board:makeList()
  -- loop through all four directions
  for _, dir in ipairs(Point.ALL_DIRS) do
    helpers.addLine(board, pawn, moves, dir + dir:rotateCW())
  end

  return moves
end

return Bishop
