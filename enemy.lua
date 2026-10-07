local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y)
    local self = setmetatable({}, Enemy)
    self.x = x
    self.y = y
    self.radius = 25
    self.speed = 250
    self.health = 20
    self.damage = 10
    self.kbx = 0
    self.kby = 0
    return self
end

function Enemy:knockback(nx, ny, force)
    self.kbx = nx * force
    self.kby = ny * force
end

function Enemy:update(dt, player)
    --knockback
    self.x = self.x + self.kbx * dt
    self.y = self.y + self.kby * dt
    local decay = math.exp(-10 * dt)
    self.kbx, self.kby = self.kbx * decay, self.kby * decay

    --if knockbacking, staggers
    if math.abs(self.kbx) + math.abs(self.kby) > 30 then 
        return
    end

    local dx = player.x - self.x
    local dy = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        self.x = self.x + dx / dist * self.speed * dt
        self.y = self.y + dy / dist * self.speed * dt
    end
end

function Enemy:draw(board, scale)
    local sx = self.x * scale + board.offx
    local sy = self.y * scale + board.offy
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.circle("fill", sx, sy, self.radius * scale)
end

return Enemy
