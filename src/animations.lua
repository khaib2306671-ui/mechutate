return {
    slash = function (self, arc)
        local p = arc.time / arc.duration
        p = 1 - (1 - p) * (1 - p) -- ease out
        local curr = arc.from + (arc.to - arc.from) * p
        local back = math.max(arc.from, curr - 0.8)

        love.graphics.push("all")
        love.graphics.translate(self.screenX, self.screenY)
        love.graphics.scale(self.scale)
        love.graphics.setColor(1, 1, 1, 1 - p * 0.7)
        love.graphics.setLineWidth(20 / self.scale)
        love.graphics.arc("line", "open", 0, 0, arc.radius, back, curr)
        love.graphics.pop()
    end
}