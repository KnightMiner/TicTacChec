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
  "rook",
  "pawn",
  "bishop",
  "knight",
}

-- objects so we can interact with pieces
white = {}
black = {}

function printTable(data)
  print(table.concat(data, ", "))
end

-- add all pawns to the board
local count = 0
for key, pawnType in pairs(types) do
  count = count + 1
  local icon
  if type(pawnType) == "string" then
    icon = pawnType
    pawnType = require("pawnTypes/" .. pawnType)
  else
    icon = pawnType:GetIcon()
  end
  white[icon] = Pawn(pawnType, Color.WHITE)
  black[icon] = Pawn(pawnType, Color.BLACK)
  board:addPawn(white[icon])
  board:addPawn(black[icon])
end

-- set up network stuff
def = Agent.makeDefinition{players = 2, pawns = count, layers = {7}}
white.agent = Agent{network = def:generate()}
white.agent:setBoard(board, Color.WHITE)
black.agent = Agent{network = def:generate()}
black.agent:setBoard(board, Color.BLACK)
gens = {}
gens[1] = Generation.generate(def, 100)
gens[1]:playGames(5, 20, 5)
print(string.format("Generation 1, best %.1f, average %.2f", gens[1]:getBestAgent():getAverageScore(), gens[1]:getAverageScore()))
for i = 2, 5 do
  gens[i] = gens[i-1]:reproduce{
    count = 100,
    mutationChance = 1 / i,
    clones = 5,
    rand = 1
  }
  gens[i]:playGames(5, 10 * math.floor(math.sqrt(i)), 5)
  print(string.format("Generation %d, best %.1f, average %.2f", i, gens[i]:getBestAgent():getAverageScore(), gens[i]:getAverageScore()))
end

-- print the board to start
print(board)

return ""
