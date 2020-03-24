local Point = require("point")

-- final return
local Color = {}

local ColorClass = {}
ColorClass.__index = ColorClass

--[[--
  Creates a new color object
]]
function ColorClass:new(object)
  local object = object or {}
  setmetatable(object, self)
  return object
end

--[[--
  Gets the direction for pawn movement for this color
]]
function ColorClass:getDir()
  return self.dir
end

--[[--
  Gets the name of this color
]]
function ColorClass:getName()
  return self.name
end

--- White color
Color.WHITE = ColorClass:new{
  name = "white",
  char = string.char(219),
  ansi = 37,
  dir = Point.DOWN
}
--- Black color
Color.BLACK = ColorClass:new{
  name = "black",
  char = " ",
  ansi = 91,
  dir = Point.UP
}
--- Color for spaces
Color.SPACE = ColorClass:new{
  char = " ",
  ansi = 92
}
--- Color for header numbers
Color.HEADER = ColorClass:new{
  char = " ",
  ansi = 37
}

--- If true, we support ansi colors
local isAnsi = false

--- Ansi escape character
local ANSI_CHAR = string.char(27)
local ANSI_FORMAT = ANSI_CHAR .. "[%s;%sm%s" .. ANSI_CHAR .. "[0m"


--[[--
  Checks if the given object is a Color

  @param color   Object to check if its a Color
  @return  true if its a Color
]]
function Color.isA(color)
  return getmetatable(color) == ColorClass
end

--[[--
  Sets if we support ansi colors

  @param ansi  True if ansi is enabled
]]
function Color.setAnsi(ansi)
  isAnsi = ansi
end

--[[--
  Checks if we support ansi colors

  @return   True if ansi is enabled
]]
function Color.isAnsi()
  return isAnsi
end

--[[--
  Color the given space

  @param point  Point to color
  @param name   Piece name
  @param point  Piece color
]]
function Color.space(point, name, color)
  name = name and tostring(name) or ""
  color = color or Color.BLACK
  assert(point == nil or Point.isA(point), "Parameter 1 must be a point")
  assert(Color.isA(color), "Parameter 3 must be a color")

  -- make name 2 characters
  local len = string.len(name)
  if len == 1 then
    name = " " .. name
  elseif len > 2 then
    name:sub(1,2)
  end

  -- if ansi, print with colors
  if isAnsi then
    -- if the space is empty, return an empty string
    if name == "" then
      name = "  "
    end

    -- bg based on space
    local background = (point == nil or (point.x + point.y)%2 == 0) and 40 or 100
    return string.format(ANSI_FORMAT, color.ansi, background, name)
  else
    -- if the space is empty, return an empty string
    if name == "" then
      return "   "
    end
    -- simply suffix name with the color character
    return name .. color.char
  end
end

--[[--
  Colors the passed text

  @param color  color to use
  @param text   Text to return
]]
function Color.color(color, text)
  if isAnsi then
    return string.format(ANSI_FORMAT, color.ansi, 4, text)
  else
    return text
  end
end

return Color
