--package.path = "../?.lua;" .. package.path

-- imports
local Color = require("color")
local Board = require("board")
local Point = require("point")
local Generation = require("generation")

-- fetch args
local args = {...}
assert(#args < 3, "Usage: lua cmd.lua [color] [generation]")
local agent
-- first arg determines starting player
local isWhite = true
if #args > 0 then
  assert(args[1] == "black" or args[1] == "white", "Invalid color")
  isWhite = args[1] ~= "black"
end
-- second arg is either count or agent
local count = 4
if #args == 2 then
  -- numbers are count
  local number = tonumber(args[2])
  if number ~= nil then
    count = number
  else
    -- anything else is agent
    local gen = Generation.read(args[2])
    agent = gen:getBestAgent()
    count = agent:getPawnCount()
  end
  assert(count > 2 and count <= 5, "Invalid count, must be between 3 and 5")
end

-- create board
local board = Board(count)

-- add pieces to the board
-- true means use the key name as the pawn type
-- or use require to set a specific type
local types = {
  "rook",
  "pawn",
  "bishop",
  "knight",
  "king"
}

-- piece short names
local aliases = {
  kn = "knight",
  ro = "rook",
  bi = "bishop",
  pa = "pawn",
  ki = "king"
}

-- objects so we can interact with pieces
local white = {}
local black = {}

print("Valid pieces:")

-- add all pawns to the board
local Pawn = require("pawn")
for i = 1, count do
  local type = types[i]
  print("* " .. type)
  local class = require("pawnTypes/" .. type)
  --- create pieces
  white[type] = Pawn(class, Color.WHITE)
  black[type] = Pawn(class, Color.BLACK)
  -- add to game
  board:addPawn(white[type])
  board:addPawn(black[type])
end

-- setup agent
if agent then
  agent:setBoard(board, Color.BLACK)
end

-- alternate players
while board:getWinner() == nil do
  -- information
  print()
  local color = isWhite and Color.WHITE or Color.BLACK
  print(Color.color(color, color:getName() .. "'s turn"))
  print(board)

  --- agent move making
  if not isWhite and agent then
    agent:makeMove()
    isWhite = true
  else
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
end

-- print final winner
print(board)
