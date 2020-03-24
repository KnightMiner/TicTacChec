--package.path = "../?.lua;" .. package.path

-- imports
local Color = require("color")
local Board = require("board")
Point = require("point")

-- setup
Color.setAnsi(false)
-- create board
board = Board(4)

-- add pieces to the board
-- true means use the key name as the pawn type
-- or use require to set a specific type
local Pawn = require("pawn")
local types = {
  rook   = true,
  knight = true,
  bishop = true,
  pawn   = true
}

-- objects so we can interact with pieces
white = {}
black = {}

-- add all pawns to the board
local Pawn = require("pawn")
for key, type in pairs(types) do
  if type == true then
    type = require("pawnTypes/" .. key)
  end
  white[key] = Pawn(type, Color.WHITE)
  black[key] = Pawn(type, Color.BLACK)
  board:addPawn(white[key])
  board:addPawn(black[key])
end

-- print the board to start
print(board)

return ""
