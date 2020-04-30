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

--[[--
  Quick function to print an array as a comma separated string
]]
function printTable(data)
  print(table.concat(data, ", "))
end

--[[--
  Sets up a game to play against an agent
]]
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
  return board
end

--[[
Generations:
  Gen 0: control
  Gen 1: mutationChance = 0.1
  Gen 2: layers = {32, 24}
  Gen 3: frequency = 2
  Gen 4: pawns = 5
  Gen 5: layers = {8, 6}
]]
--[[--
  Runs the geneations as set up
]]
function run()
  local def = Agent.makeDefinition{players = 2, pawns = 4, layers = {16, 12}}
  local time = os.time()
  print("Starting generations")
  local gen = Generation.generate(def, 100)
  gens = gen:run{
    generations = 250,
    -- breeding
    mutationChance = 0.05,
    clones = 8,
    rand = 2,
    -- games
    games = 5,
    moves = 50,
    frequency = 5
  }
  print(string.format("Finished generations in %d seconds", os.time() - time))
end

return run
