--package.path = "../?.lua;" .. package.path

-- imports
Color = require("color")
Pawn = require("pawn")
local Board = require("board")
Point = require("point")
Generation = require("generation")
Agent = require("agent")

-- create board
board = Board(4)

-- add pieces to the board
-- true means use the key name as the pawn type
-- or use require to set a specific type
local PawnType = require("pawnTypes/pawn")
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
local count = 0
for key, type in pairs(types) do
  count = count + 1
  if type == true then
    type = require("pawnTypes/" .. key)
  end
  white[key] = Pawn(type, Color.WHITE)
  black[key] = Pawn(type, Color.BLACK)
  board:addPawn(white[key])
  board:addPawn(black[key])
end

-- set up network stuff
def = Agent.makeDefinition{players = 2, pawns = count, layers = {6}}
white.agent = Agent{network = def:generate()}
white.agent:setBoard(board, Color.WHITE)
black.agent = Agent{network = def:generate()}
black.agent:setBoard(board, Color.BLACK)

-- print the board to start
print(board)

return ""
