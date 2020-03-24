local helpers = {}

--[[--
  Adds a point to the move list if it can be attacked

  @param board  Board instance
  @param pawn   Pawn moving
  @param moves  Move list
  @param point  Point to check
  @return  true if should continue checking spaces behind
]]
function helpers.addPoint(board, pawn, moves, point)
  -- check if there is a pawn on the space
  local current = board:getPawnAt(point)
  if current ~= nil then
    -- if there is, can move there if not our color
    if not current:isColor(pawn) then
      moves:add(point)
    end
    -- cannot leap over pawns
    return false
  end
  -- empty? space is fine
  moves:add(point)
  return true
end

--[[--
  Adds a line of spaces to the move list

  @param board  Board instance
  @param pawn   Pawn moving
  @param moves  Move list
  @param dir    Point direction
]]
function helpers.addLine(board, pawn, moves, dir)
  -- loop while the space is valid
  local point = pawn:getSpace() + dir
  while board:isValid(point) do
    -- add the point, stop if done
    if not helpers.addPoint(board, pawn, moves, point) then
      break
    end
    -- increment for next time
    point = point + dir
  end
end

return helpers
