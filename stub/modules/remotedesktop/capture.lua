-- Backup the original print, term.write, and cursor functions
local originalPrint = print
local originalTermWrite = term.write
local originalSetCursorPos = term.setCursorPos
local originalGetCursorPos = term.getCursorPos
local originalSetBackgroundColor = term.setBackgroundColor
local originalSetTextColor = term.setTextColor
local originalClear = term.clear
local originalClearLine = term.clearLine

-- Table to store the screen state
local screenMap = {}
local cursorX, cursorY = originalGetCursorPos()
local bgColor = colors.black
local textColor = colors.white

-- Function to initialize or reset the screen map
local function initializeScreenMap()
    local width, height = term.getSize()
    screenMap = {}
    for y = 1, height do
        screenMap[y] = {}
        for x = 1, width do
            screenMap[y][x] = {
                char = " ",
                bgColor = bgColor,
                textColor = textColor
            }
        end
    end
end

-- Function to update the screen map
local function updateScreenMap(x, y, char, newBgColor, newTextColor)
    if screenMap[y] and screenMap[y][x] then
        local cell = screenMap[y][x]
        if cell.char ~= char or cell.bgColor ~= newBgColor or cell.textColor ~= newTextColor then
            cell.char = char
            cell.bgColor = newBgColor
            cell.textColor = newTextColor
        end
    end
end

-- Hooked setCursorPos to track cursor position changes
local function hookedSetCursorPos(x, y)
    cursorX, cursorY = x, y
    originalSetCursorPos(x, y)
end

-- Hooked setBackgroundColor to track background color changes
local function hookedSetBackgroundColor(color)
    bgColor = color
    originalSetBackgroundColor(color)
end

-- Hooked setTextColor to track text color changes
local function hookedSetTextColor(color)
    textColor = color
    originalSetTextColor(color)
end

-- Hooked term.write to track text being written
local function hookedTermWrite(data)
    for i = 1, #data do
        local char = data:sub(i, i)
        updateScreenMap(cursorX, cursorY, char, bgColor, textColor)
        cursorX = cursorX + 1
    end
    originalTermWrite(data)
end

-- Hooked print to track printed text
local function hookedPrint(...)
    local message = table.concat({ ... }, " ")
    hookedTermWrite(message)
    cursorY = cursorY + 1
    cursorX = 1
end

-- Hooked clear to reset the screen map
local function hookedClear()
    initializeScreenMap()
    originalClear()
end

-- Hooked clearLine to reset the current line in the screen map
local function hookedClearLine()
    local width = term.getSize()
    for x = 1, width do
        updateScreenMap(x, cursorY, " ", bgColor, textColor)
    end
    originalClearLine()
end

-- Function to get the current screen map as JSON
local function getScreenMapAsJSON()
    local textutils = require("textutils")
    return textutils.serializeJSON(screenMap)
end

-- Replace the original functions with the hooked versions
_G.print = hookedPrint
term.write = hookedTermWrite
term.setCursorPos = hookedSetCursorPos
term.setBackgroundColor = hookedSetBackgroundColor
term.setTextColor = hookedSetTextColor
term.clear = hookedClear
term.clearLine = hookedClearLine

-- Initialize the screen map at startup
initializeScreenMap()

-- Return the API for external use
return {
    getScreenMapAsJSON = getScreenMapAsJSON,
    initializeScreenMap = initializeScreenMap
}
