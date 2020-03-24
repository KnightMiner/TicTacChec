--package.path = "../?.lua;" .. package.path

-- imports
local Color = require("color")
local Board = require("board")
local Point = require("point")

-- setup
Color.setAnsi(true)

-- create board
local board = Board(4)

-- add pieces to the board
-- true means use the key name as the pawn type
-- or use require to set a specific type
local types = {
  rook   = true,
  knight = true,
  bishop = true,
  pawn   = true
}

-- piece short names
local aliases = {
  kn = "knight",
  ro = "rook",
  bi = "bishop",
  pa = "pawn"
}

-- objects so we can interact with pieces
local white = {}
local black = {}

print("Valid pieces:")

-- add all pawns to the board
local Pawn = require("pawn")
for key, type in pairs(types) do
  print("* " .. key)
  if type == true then
    type = require("pawnTypes/" .. key)
  end
  --- create pieces
  white[key] = Pawn(type, Color.WHITE)
  black[key] = Pawn(type, Color.BLACK)
  -- add to game
  board:addPawn(white[key])
  board:addPawn(black[key])
end

-- alternate players
local isWhite = true
while board:getWinner() == nil do
  -- information
  print()
  local color = isWhite and Color.WHITE or Color.BLACK
  print(Color.color(color, color:getName() .. "'s turn"))
  print(board)
  -- prompt
  local input = io.read()
  if input == "exit" then break end
  local match = {string.gmatch(input, "(%w+) (%d+),%s*(%d+)")()}
  -- insure data is valid
  if #match == 3 then
    -- ensure piece is valid
    local team = isWhite and white or black
    local name = match[1]:lower()
    name = aliases[name] or name
    local pawn = team[name]
    if pawn == nil then
      print("Invalid piece " .. name)
    else
      -- ensure move is valid
      local validMoves = pawn:getValidMoves()
      local point = Point(tonumber(match[2]), tonumber(match[3]))
      if validMoves:contains(point) then
        pawn:moveOrAddTo(point)
        isWhite = not isWhite
      else
        print("Invalid move for " .. name .. ", valid moves:")
        print(validMoves)
      end
    end
  else
    print("Invalid input, format: 'piece x,y'")
  end
end

-- print final winner
print(board)
