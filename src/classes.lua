--character classes
local animations = require "animations"
class = {}
class["Sword"] ={
    vertices = {
        -12.5, -12.5,
        12.5, -12.5,
        6.25, 12.5,
        -6.25, 12.5
        },
    attack = function(self, arc, damage)
        if self.swinging then
            return
        end
        self.swinging = {
            time = 0,
            duration = 0.2,
            from = self.aim - arc / 2,
            to = self.aim + arc / 2,
            radius = 70,
            damage = damage,
            knockback = 250,
            animation = animations.slash,
        }
    end
}
class["Bow"] = {
    vertices = {
        -12.5, -12.5,
        0, -5,
        12.5, -12.5,
        12.5, 4,
        0, 12.5,
        -12.5, 4
            }
}

return class