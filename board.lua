local Board = {}
Board.__index = Board

function Board:new(size, screenx, screeny)
    local self = setmetatable({}, Board)
    self.sizex = size
    self.sizey = size
    self.side = screeny * 0.9           -- board size on screen
    self.offx = (screenx-screeny*0.9)/2 -- left
    self.offy = screeny * 0.05          -- top
    return self
end

function Board:update(dt)

end

function Board:draw()
    love.graphics.push("all")
    love.graphics.setLineWidth(10)
    love.graphics.rectangle("line", self.offx, self.offy, self.side, self.side)
    love.graphics.pop()
end

return Board

