local PawnType = require("pawnType")
local Point = require("point")
local helpers = require("helpers")

local Queen = PawnType:new({icon = "Qu"})

--[[--
  Gets a list of valid moves for this pawn

  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function Queen:getValidMoves(pawn)
  local moves = pawn:getBoard():makeList()
  -- loop through all four directions
  for _, dir in ipairs(Point.ALL_DIRS) do
    -- run normal, and rotate once for diagonal
    helpers.addLine(pawn, moves, dir)
    helpers.addLine(pawn, moves, dir + dir:rotateCW())
  end

  return moves
end

return Queen
