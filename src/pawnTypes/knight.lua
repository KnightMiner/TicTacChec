local PawnType = require("pawnType")
local Point = require("point")

--- List of all four orthogonal directions
local VALID_DIRECTIONS = {
  [0.0625] = Point( 1, -2),
  [0.1875] = Point( 2, -1),
  [0.3125] = Point( 2,  1),
  [0.4375] = Point( 1,  2),
  [0.5625] = Point(-1,  2),
  [0.6875] = Point(-2,  1),
  [0.8125] = Point(-2, -1),
  [0.9375] = Point(-1, -2),
}
local Knight = PawnType:new({icon = "Kn", directions = VALID_DIRECTIONS})

--[[--
  Gets a list of valid moves for this pawn

  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function Knight:getValidMoves(pawn)
  local board = pawn:getBoard()
  local moves = board:makeList()
  local space = pawn:getSpace()
  -- loop through all eight valid directions
  for _, offset in pairs(VALID_DIRECTIONS) do
    local leap = space + offset
    if board:isValid(leap) and not board:isColorAt(pawn, leap) then
      moves:add(leap)
    end
  end

  return moves
end

return Knight
