local PawnType = require("pawnType")
local Point = require("point")

local Pawn = PawnType:new({icon = "Kn"})

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
    -- start two spaces forwards
    local point = space + dir*2
    -- extend to either side
    for angle = -90, 90, 180 do
      local leap = point + dir:rotate(angle)
      if board:isValid(leap) and not board:isColorAt(pawn, leap) then
        moves:add(leap)
      end
    end
  end

  return moves
end

return Pawn
