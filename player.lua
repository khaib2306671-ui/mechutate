local Player = {}
Player.__index = Player

function Player:new ()
    local self = setmetatable({}, Player)
    Classes = require "classes"
    self.x = 800
    self.y = 800
    self.class = Classes["Sword"]
    self.vertices = {
        -12.5, -12.5,
        12.5, -12.5,
        6.25, 12.5,
        -6.25, 12.5
    } -- default shape if no class is chosen
    self.vertices = scalet(self.vertices, 1)
    self.triangles = love.math.triangulate(self.vertices)
    self.radius = 25
    self.speed = 150
    self.aim = 0
    self.angle = 0

    self.maxHealth = 100
    self.health = self.maxHealth
    self.invuln = 0
    self.invulnDuration = 0.5

    self.damage = 10
    self.swingArc = math.pi
    self.reach = 70
    self.knockbackForce = 250
    self.swingDuration = 0.2

    return self
end

function Player:takeDamage(amount)
    if self.invuln > 0 then
        return false
    end
    self.health = math.max(0, self.health - amount)
    self.invuln = self.invulnDuration
    return true
end

function Player:isDead()
    return self.health <= 0
end

function Player:heal(amount)
    self.health = math.min(self.maxHealth, self.health + amount)
end

function Player:attack()
    if self.class.attack then
        self.class.attack(self, self.swingArc, self.damage)
    end
end

function scalet(table, scale)
    t = {}
    for i, v in ipairs(table) do
        t[i] = v * scale
    end
    return t
end

function Player:update(dt, board)
    if love.keyboard.isDown("a") and self.x - self.radius >= 0 then
        self.x = self.x - self.speed * dt
    end
    if love.keyboard.isDown("d") and self.x + self.radius <= board.sizex then
        self.x = self.x + self.speed * dt
    end
    if love.keyboard.isDown("w") and self.y - self.radius >= 0 then
        self.y = self.y - self.speed * dt
    end
    if love.keyboard.isDown("s") and self.y + self.radius <= board.sizey then
        self.y = self.y + self.speed * dt
    end
    if love.mouse.isDown(1) then
        self:attack()
    end


    local mx, my = love.mouse.getPosition()
    self.scale = screeny / board.sizey * 0.9
    self.screenX = self.x * self.scale + board.offx
    self.screenY = self.y * self.scale + board.offy
    ---@diagnostic disable-next-line: deprecated
    self.aim = math.atan2(my - self.screenY, mx - self.screenX)
    self.angle = self.aim - math.pi / 2

    self.invuln = math.max(0, self.invuln - dt)
    if self.swinging then
        self.swinging.time = self.swinging.time + dt
        if self.swinging.time >= self.swinging.duration then
            self.swinging = nil
        end
    end
end

function Player:draw (board)
    love.graphics.push("all")
    love.graphics.translate(self.screenX, self.screenY)
    love.graphics.rotate(self.angle)
    for _, tri in ipairs(self.triangles) do
        love.graphics.polygon("fill", tri)
    end
    love.graphics.pop()

    if self.swinging then
        self.swinging.animation(self, self.swinging)
    end
    
    if self.invuln > 0 and math.floor(self.invuln * 20) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.25)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Player

