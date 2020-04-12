local PawnType = require("pawnType")
local Point = require("point")
local helpers = require("helpers")

local King = PawnType:new({icon = "Ki"})

--[[--
  Gets a list of valid moves for this pawn

  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function King:getValidMoves(pawn)
  local moves = pawn:getBoard():makeList()
  local space = pawn:getSpace()
  -- loop through all four directions
  for _, dir in ipairs(Point.ALL_DIRS) do
    -- run normal, and rotate once for diagonal
    helpers.addPoint(pawn, moves, space + dir)
    helpers.addPoint(pawn, moves, space + dir + dir:rotateCW())
  end

  return moves
end

return King
