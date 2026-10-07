-- took some stuffs from gamestate.lua in hump - Helper Utilities for Massive Progression by Matthias Richter (vrld)
-- https://github.com/vrld/hump

local Map = {}
Map.__index = Map

local TYPES = {
    { name = "fight", color = { 1, 0.25, 0.25 } },
    { name = "elite", color = { 1, 0.85, 0.1 } },
    { name = "rest",  color = { 0.2, 0.8, 0.3 } },
    { name = "drop point",  color = { 0.7, 0.3, 0.8 } },
}

local SPACING = 110
local MIN_GAP = 80
local NODE_R = 10   -- node radius

local function dist(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

-- do line a-b and line c-d cross? (lines sharing an end don't count)
local function segmentsCross(a, b, c, d)
    if a == c or a == d or b == c or b == d then return false end
    local function side(p, q, r)
        return (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x)
    end
    return (side(c, d, a) > 0) ~= (side(c, d, b) > 0)
        and (side(a, b, c) > 0) ~= (side(a, b, d) > 0)
end

function Map:crossesAny(a, b)
    for _, e in ipairs(self.edges) do
        if segmentsCross(a, b, e[1], e[2]) then return true end
    end
    return false
end

function Map:isFree(x, y)
    for _, n in ipairs(self.nodes) do
        if dist(n, { x = x, y = y }) < MIN_GAP then return false end
    end
    return true
end

local function connected(a, b)
    for _, n in ipairs(a.neighbors) do
        if n == b then return true end
    end
    return false
end

function Map:connect(a, b)
    table.insert(a.neighbors, b)
    table.insert(b.neighbors, a)
    table.insert(self.edges, { a, b })
end

function Map:addNode(x, y, depth)
    local node = {
        x = x,
        y = y,
        depth = depth,
        waves = math.floor(3 + depth*0.35),
        neighbors = {},
        cleared = false,
    }
    node.type = depth == 0 and TYPES[1] or TYPES[love.math.random(#TYPES)]
    table.insert(self.nodes, node)
    return node
end

function Map.new(nodeCount)
    local self = setmetatable({}, Map)
    self.nodes = {}
    self.edges = {}

    local start = self:addNode(0, 0, 0)
    local frontier = { start }

    while #self.nodes < nodeCount and #frontier > 0 do
        local parent = table.remove(frontier, love.math.random(#frontier))

        local outward, spread
        if parent.depth == 0 then
            outward, spread = 0, math.pi
        else
            ---@diagnostic disable-next-line: deprecated
            outward, spread = math.atan2(parent.y, parent.x), math.pi / 2
        end

        for _ = 1, love.math.random(1, 3) do
            for _ = 1, 10 do -- a few tries to find a free spot
                local a = outward + (love.math.random() * 2 - 1) * spread
                local x = parent.x + math.cos(a) * SPACING
                local y = parent.y + math.sin(a) * SPACING
                if self:isFree(x, y) and not self:crossesAny(parent, { x = x, y = y }) then
                    local child = self:addNode(x, y, parent.depth + 1)
                    self:connect(parent, child)
                    table.insert(frontier, child)
                    break
                end
            end
        end
    end

    for i, a in ipairs(self.nodes) do
        for j = i + 1, #self.nodes do
            local b = self.nodes[j]
            if dist(a, b) < SPACING * 1.5 and not connected(a, b)
                and love.math.random() < 0.2 and not self:crossesAny(a, b) then
                self:connect(a, b)
            end
        end
    end

    self.current = start
    self.camX, self.camY = 0, 0
    return self
end

function Map:canMoveTo(node)
    return self.current.cleared and connected(self.current, node)
end

function Map:update(dt)
    local t = 1 - math.exp(-6 * dt)
    self.camX = self.camX + (self.current.x - self.camX) * t
    self.camY = self.camY + (self.current.y - self.camY) * t
end

function Map:nodeAt(x, y)
    local mx = x - love.graphics.getWidth() / 2 + self.camX
    local my = y - love.graphics.getHeight() / 2 + self.camY
    for _, n in ipairs(self.nodes) do
        if dist(n, { x = mx, y = my }) <= NODE_R * 2 then
            return n
        end
    end
end

function Map:mousepressed(x, y)
    local n = self:nodeAt(x, y)
    if n and self:canMoveTo(n) then
        return n
    end
end

function Map:draw()
    love.graphics.push("all")
    love.graphics.translate(love.graphics.getWidth() / 2 - self.camX,
        love.graphics.getHeight() / 2 - self.camY)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(0.8, 0.8, 0.8)
    for _, e in ipairs(self.edges) do
        love.graphics.line(e[1].x, e[1].y, e[2].x, e[2].y)
    end

    for _, n in ipairs(self.nodes) do
        local c = n.type.color
        local alpha = n.cleared and 0.35 or 1
        love.graphics.setColor(c[1], c[2], c[3], alpha)
        love.graphics.circle("fill", n.x, n.y, NODE_R)

        if self:canMoveTo(n) then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", n.x, n.y, NODE_R + 6)
        end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", self.current.x, self.current.y, NODE_R + 12)

    -- label the hovered node with its type
    local hovered = self:nodeAt(love.mouse.getPosition())
    if hovered then
        local label = (hovered.type.name:gsub("^%l", string.upper)) -- "drop point" -> "Drop point"
        if hovered.cleared then
            label = label .. " (cleared)"
        end
        local c = hovered.type.color
        love.graphics.setColor(c[1], c[2], c[3])
        love.graphics.printf(label, hovered.x - 100, hovered.y - NODE_R - 25, 200, "center")
    end

    love.graphics.pop()
end

return Map
