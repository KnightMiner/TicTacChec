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
    count = 0,
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
  Checks if the given point is within the list size

  @param point  Point
  @return true if the point is within the list size
]]
function PointList:isValid(point)
  assert(Point.isA(point), "Argument must be instance of point")
  return point.x >= 0 and point.x < self.size and point.y >= 0 and point.y < self.size
end

--[[--
  Adds a point to the list

  @param point  Point to add
  @return  true if a point was added
]]
function PointList:add(point)
  assert(Point.isA(point), "Argument must be a point")
  assert(self:isValid(point), "Point outside of list size")
  -- if its not contained, increase the count and return true
  local index = point:getIndex(self.size)
  if self.points[index] == nil then
    self.count = self.count + 1
    self.points[index] = point
    return true
  end
  return false
end

--[[--
  Checks if the list contains the given point

  @param point  Point to check for
  @return true if the point is contained, false otherwise
]]
function PointList:contains(point)
  assert(Point.isA(point), "Argument must be a point")
  -- if the point is outside the list, its index may be a point without being the point
  return self.points[point:getIndex(self.size)] == point
end

--[[--
  Removes a point from the list

  @param point  Point to remove
  @return  true if a point was removed
]]
function PointList:remove(point)
  assert(Point.isA(point), "Argument must be a point")
  assert(self:isValid(point), "Point outside of list size")
  local index = point:getIndex(self.size)
  -- remove if its present and decrease the count
  if self.points[index] ~= nil then
    self.count = self.count - 1
    self.points[index] = nil
    return true
  end
  return false
end

--[[--
  Checks if the given point list is empty

  @return  true if the list is empty
]]
function PointList:isEmpty()
  return self.count == 0
end

--[[--
  Converts the point list to a string

  @return  string of this point list
]]
function PointList:__tostring()
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
      table.insert(line, Color.space(space, self:contains(space) and 'X' or ' ', Color.SPACE))
    end
    table.insert(out, table.concat(line, "|"))
  end
  return table.concat(out, "\n")
end

return PointList
