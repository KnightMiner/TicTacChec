local Point = {}
Point.__index = Point

--[[--
  Constructor: creates a new point

  @param x  Point X value
  @param y  Point Y value
  @return  Point object
]]
function Point:new(x, y)
  assert(type(x) == "number", "X must be a number")
  assert(type(y) == "number", "Y must be a number")
  return setmetatable({
    x = math.floor(x+.5),
    y = math.floor(y+.5)
  }, self)
end

-- allow calling Point() as an alternative to Point:new()
setmetatable(Point, {__call = Point.new})

--[[--
  Checks if the given object is a point

  @param point   Object to check if its a point
  @return
]]
function Point.isA(point)
  return getmetatable(point) == Point
end

--- Both are allowed to be points
local MODE_BOTH = 0
--- Left only can be a point, right number
local MODE_LEFT = 1
--- Either option can be a point, but not both
local MODE_ONE  = 2

--[[--
  Helper function to handle binary operations

  @param name  Operation name
  @param mode  Determines whih of a and b must be points
  @param op    Operation function
  @param a     Left parameter
  @param b     Right parameter
]]
local function binaryOp(name, mode, op, left, right)
  -- points
  if Point.isA(left) then
    -- both points
    if Point.isA(right) then
      -- error if invalid with both
      assert(mode == MODE_BOTH, string.format("Cannot %s point and point", name))
      return Point(op(left.x, right.x), op(left.y, right.y))
    end
    -- numbers
    local typeR = type(right)
    assert(typeR == "number", string.format("Cannot %s point and %s", name, typeB))
    -- perform operation
    return Point(op(left.x, right), op(left.y, right))
  end

  -- this should never happen
  assert(Point.isA(right), "Calling point metafunctions with no point")

  -- if left only, error
  assert(mode ~= MODE_LEFT, string.format("Cannot %s using point", name))

  -- point is B, A is other
  local typeL = type(left)
  assert(typeL == "number", string.format("Cannot %s %s and point", name, typeL))
  -- perform operation
  return Point(op(left, right.x), op(left, right.y))
end

--[[--
  Logic to add two points together

  @param other  Number or point to add to this point
  @return  new point instance
]]
function Point.__add(left, right)
  return binaryOp("add", MODE_BOTH, function(a,b) return a+b end, left, right)
end

--[[--
  Logic to subtract two points together

  @param other  Number or point to subtract from this point
  @return  new point instance
]]
function Point.__sub(left, right)
  return binaryOp("divide", MODE_BOTH, function(a,b) return a-b end, left, right)
end

--[[--
  Logic to multiply a point by a scalar

  @param other  Scalar to multiply
  @return  new point instance
]]
function Point.__mul(left, right)
  return binaryOp("multiply", MODE_ONE, function(a,b) return a*b end, left, right)
end

--[[--
  Logic to divide a point by a scalar

  @param other  Scalar
  @return  new point instance
]]
function Point.__div(left, right)
  return binaryOp("multiply", MODE_LEFT, function(a,b) return a/b end, left, right)
end

--[[--
  Logic to apply modulo to a point by a scalar

  @param other  Scalar
  @return  new point instance
]]
function Point.__mod(left, right)
  return binaryOp("multiply", MODE_LEFT, function(a,b) return a%b end, left, right)
end

--[[--
  Logic to apply modulo to a point by a scalar

  @param other  Scalar
  @return  new point instance
]]
function Point.__unm(self)
  return Point(-self.x, -self.y)
end

--[[--
  Logic to apply modulo to a point by a scalar

  @param other  Scalar
  @return  new point instance
]]
function Point.__eq(left, right)
  return Point.isA(left) and Point.isA(right)
    and left.x == right.x and left.y == right.y
end

--[[--
  Logic to apply modulo to a point by a scalar

  @param other  Scalar
  @return  new point instance
]]
function Point:__tostring()
  return string.format("Point(%s,%s)", self.x, self.y)
end

--[[--
  Rotates the given point clockwise by the angle

  @param angle  Angle clockwise, in increments of 90 degrees
  @return new point rotated clockwise by angle
]]
function Point:rotate(angle)
  assert(self ~= Point, "Attempt to call instance method statically")
  assert(type(angle) == "number", "Angle must be a number")
  assert(angle % 90 == 0, "Angle must be in increments of 90 degrees")
  local rad = math.rad(angle)
  local sin = math.sin(rad)
  local cos = math.cos(rad)
  return Point(cos * self.x - sin * self.y, sin * self.x + cos * self.y)
end

--[[--
  Rotates the given point clockwise

  @return new point rotated clockwise
]]
function Point:rotateCW()
  assert(self ~= Point, "Attempt to call instance method statically")
  return Point(-self.y, self.x)
end

--[[--
  Rotates the given point counterclockwise

  @return new point rotated counterclockwise
]]
function Point:rotateCCW()
  assert(self ~= Point, "Attempt to call instance method statically")
  return Point(self.y, -self.x)
end

--[[--
  Flips the point vertically

  @return new point rotated counterclockwise
]]
function Point:flipV()
  assert(self ~= Point, "Attempt to call instance method statically")
  return Point(self.x, -self.y)
end

--[[--
  Flips the point horizontally

  @return new point rotated counterclockwise
]]
function Point:flipH()
  assert(self ~= Point, "Attempt to call instance method statically")
  return Point(-self.x, self.y)
end

-- constants
--- Negative Y direction
Point.UP = Point(0,-1)
--- Positive Y direction
Point.DOWN = Point(0, 1)
--- Negative X direction
Point.LEFT = Point(-1, 0)
--- Positive X direction
Point.RIGHT = Point(1, 0)

--- Direction lists
Point.ALL_DIRS = {Point.UP, Point.RIGHT, Point.DOWN, Point.LEFT}
Point.VERTICALS = {Point.UP, Point.DOWN}
Point.HORIZONTALS = {Point.LEFT, Point.RIGHT}

return Point
