local Color = require("color")
local Point = require("point")

local PointList = {}
PointList.__index = PointList

--[[--
  Creates a new point list

  @param size  Board size of list
]]
function PointList:new(size)
  assert(type(size) == "number", "Size must be a number")
  return setmetatable({
    size = size,
    points = {}
  }, self)
end

-- allow calling PointList() as an alternative to PointList:new()
setmetatable(PointList, {__call = PointList.new})

--[[--
  Checks if the given object is a Board

  @param board   Object to check if its a Board
  @return  true if its a board
]]
function PointList.isA(list)
  return getmetatable(list) == PointList
end

--[[--
  Adds a point to the list

  @param point  Point to add
]]
function PointList:add(point)
  assert(Point.isA(point), "Argument must be a point")
  table.insert(self.points, point)
end

--[[--
  Checks if the list contains the given point

  @param point  Point to check for
  @return true if the point is contained, false otherwise
]]
function PointList:contains(point)
  assert(Point.isA(point), "Argument must be a point")
  for _, v in ipairs(self.points) do
    if v == point then
      return true
    end
  end
  return false
end

--[[--
  Converts the point list to a string

  @return  string of this point list
]]
function PointList:__tostring()
  -- make a map of all points
  local points = {}
  for _, point in self() do
    points[tostring(point)] = true
  end

  -- print given points
  local out = {}
  -- start with a header
  local line = {}
  table.insert(line, Color.space(Point(-1,-1), "", Color.HEADER))
  for x = 0, self.size - 1 do
    table.insert(line, Color.space(Point(x,-1), x, Color.HEADER))
  end
  table.insert(out, table.concat(line, "|"))
  -- main data
  for y = 0, self.size - 1 do
    -- header column
    line = {}
    table.insert(line, Color.space(Point(-1,y), y, Color.HEADER))
    for x = 0, self.size - 1 do
      local space = Point(x, y)
      table.insert(line, Color.space(space, points[tostring(space)] and 'X' or ' ', Color.SPACE))
    end
    table.insert(out, table.concat(line, "|"))
  end
  return table.concat(out, "\n")
end

--[[--
  Iterator over point list
]]
function PointList:__call()
  return ipairs(self.points)
end

return PointList
