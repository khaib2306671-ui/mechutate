local Enemy = require "enemy"

local Waves = {}
Waves.__index = Waves

function Waves.new(board, maxWaves)
    local self = setmetatable({}, Waves)
    self.board = board
    self.wave = 0
    self.enemies = {}
    self.toSpawn = 0
    self.spawnTimer = 0
    self.spawnInterval = 0.8
    self.breakTimer = 2
    self.maxWaves = maxWaves
    self.done = false
    return self
end

function Waves:startNextWave()
    self.wave = self.wave + 1
    self.toSpawn = 3 + self.wave * 2
    self.spawnTimer = 0
end

-- spawn one enemy just outside a random edge of the board
function Waves:spawnOne()
    local b = self.board
    local margin = 50 -- how far outside the edge it starts
    local side = love.math.random(4)
    local x, y
    if side == 1 then     -- top
        x, y = love.math.random() * b.sizex, -margin
    elseif side == 2 then -- bottom
        x, y = love.math.random() * b.sizex, b.sizey + margin
    elseif side == 3 then -- left
        x, y = -margin, love.math.random() * b.sizey
    else                  -- right
        x, y = b.sizex + margin, love.math.random() * b.sizey
    end
    table.insert(self.enemies, Enemy.new(x, y))
end


function Waves:checkSwing(player)
    local s = player.swinging
    if not s then return end
    s.hit = s.hit or {}
    local center = (s.from + s.to) / 2
    local half = (s.to - s.from) / 2

    for _, e in ipairs(self.enemies) do
        if not s.hit[e] then
            local dx, dy = e.x - player.x, e.y - player.y
            local dist = math.sqrt(dx * dx + dy * dy)
            ---@diagnostic disable-next-line: deprecated
            local angle = math.atan2(dy, dx)
            local diff = (angle - center + math.pi) % (2 * math.pi) - math.pi
            if dist <= s.radius + e.radius and math.abs(diff) <= half then
                e.health = e.health - s.damage
                s.hit[e] = true
                if s.knockback and dist > 0 then
                    e:knockback(dx / dist, dy / dist, s.knockback)
                end
            end
        end
    end
end

function Waves:checkContact(player)
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - player.x, e.y - player.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < e.radius + player.radius then
            if player:takeDamage(e.damage) and dist > 0 then
                e:knockback(dx / dist, dy / dist, 300)
            end
        end
    end
end

function Waves:update(dt, player)
    
    if self.toSpawn > 0 then
        self.spawnTimer = self.spawnTimer - dt
        if self.spawnTimer <= 0 then
            self:spawnOne()
            self.toSpawn = self.toSpawn - 1
            self.spawnTimer = self.spawnInterval
        end
    elseif #self.enemies == 0 then
        if self.wave >= self.maxWaves then
            self.done = true
            return
        end
        self.breakTimer = self.breakTimer - dt
        if self.breakTimer <= 0 then
            self:startNextWave()
            self.breakTimer = 3
        end
    end

    self:checkSwing(player)

    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        e:update(dt, player)
        if e.health <= 0 then
            table.remove(self.enemies, i)
        end
    end

    self:checkContact(player)
end

function Waves:draw(scale)
    local b = self.board
    love.graphics.push("all")
    -- only draw inside the board, so enemies appear as they cross the edge
    love.graphics.setScissor(b.offx, b.offy, b.sizex * scale, b.sizey * scale)
    for _, e in ipairs(self.enemies) do
        e:draw(b, scale)
    end
    love.graphics.pop()
end

return Waves
