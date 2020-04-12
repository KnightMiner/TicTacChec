local PawnType = require("pawnType")
local Point = require("point")
local helpers = require("helpers")

--- List of all four orthogonal directions
local VALID_DIRECTIONS = {
  [0.000] = Point.UP,
  [0.250] = Point.RIGHT,
  [0.500] = Point.DOWN,
  [0.750] = Point.LEFT
}

local Rook = PawnType:new({icon = "Ro", directions = VALID_DIRECTIONS})

--[[--
  Gets a list of valid moves for this pawn

  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function Rook:getValidMoves(pawn)
  local moves = pawn:getBoard():makeList()
  -- loop through all four directions
  for _, dir in ipairs(Point.ALL_DIRS) do
    helpers.addLine(pawn, moves, dir)
  end

  return moves
end

return Rook
