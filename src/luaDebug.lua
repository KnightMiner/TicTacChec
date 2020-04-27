--package.path = "../?.lua;" .. package.path

-- imports
Color = require("color")
Pawn = require("pawn")
local Board = require("board")
Point = require("point")
Generation = require("generation")
Agent = require("agent")

local pieces = {
  "rook",
  "pawn",
  "bishop",
  "knight",
  "king"
}

-- objects so we can interact with pieces
board = nil

function printTable(data)
  print(table.concat(data, ", "))
end

function prepareGame(agent)
  _G.agent = agent
  board = agent:makeBoard(Color.BLACK)
  local count = agent:getPawnCount()
  for i = 1, count do
    _G[pieces[i]] = board:getPawn(Color.WHITE, i)
  end
  for i = count+1, #pieces do
    _G[pieces[i]] = nil
  end
end

-- set up network stuff
def = Agent.makeDefinition{players = 2, pawns = 4, layers = {7, 7}}
local gen = Generation.generate(def, 100)
gens = gen:run{
  generations = 10,
  -- breeding
  mutationChance = 0.05,
  clones = 8,
  rand = 2,
  -- games
  games = 5,
  moves = 20,
  frequency = 3
}

return ""
