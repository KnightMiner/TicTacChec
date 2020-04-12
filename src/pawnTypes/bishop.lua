local PawnType = require("pawnType")
local Point = require("point")
local helpers = require("helpers")

--- List of all four diagonals valid for the bishop
local VALID_DIRECTIONS = {
  [0.125] = Point.UP + Point.RIGHT,
  [0.325] = Point.DOWN + Point.RIGHT,
  [0.625] = Point.DOWN + Point.LEFT,
  [0.875] = Point.UP + Point.LEFT
}

local Bishop = PawnType:new({icon = "Bi", directions = VALID_DIRECTIONS})

--[[--
  Gets a list of valid moves for this pawn

  @param pawn   Current pawn instance
  @return  PointList of valid spaces this pawn can move to
]]
function Bishop:getValidMoves(pawn)
  local moves = pawn:getBoard():makeList()
  -- loop through all four directions
  for _, dir in pairs(VALID_DIRECTIONS) do
    helpers.addLine(pawn, moves, dir)
  end

  return moves
end

return Bishop
