--- Index table, called Pawn for conveience of adding functions
local PawnType = {}
PawnType.__index = PawnType

--[[--
  Constructor: creates a new pawn type

  @param object  Pawn object data
  @return  Pawn object
]]
function PawnType:new(object)
  local object = object or {}
  setmetatable(object, self)
  -- clone metamethods to children
  self.__index = self
  self.__tostring = self.__tostring
  return object
end

--[[--
  Checks if the given object is a Board

  @param board   Object to check if its a Board
  @return  true if its a board
]]
function PawnType.isA(type)
  return getmetatable(type) == PawnType
end

--[[--
  Gets the display name of this pawn type based on the color
]]
function PawnType:__tostring()
  return self:getIcon()
end

--[[--
  Gets the display name of this pawn type based on the color
]]
function PawnType:getIcon()
  return self.icon or ""
end

--[[--
  Gets a list of valid moves for this pawn

  @param board  Board containing the pawn
  @param pawn   Current pawn instance
  @return  table of valid spaces this pawn can move to
]]
function PawnType:getValidMoves(board, pawn)
  return {}
end

return PawnType
