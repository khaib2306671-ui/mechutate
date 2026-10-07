-- rewards offered at drop points, granted after clearing all waves

local Rewards = {}

Rewards.pool = {
    {
        name = "Vitality",
        desc = "+25 max HP",
        apply = function(p)
            p.maxHealth = p.maxHealth + 25
            p.health = p.health + 25
        end,
    },
    {
        name = "Sharpened Blade",
        desc = "+5 damage",
        apply = function(p) p.damage = p.damage + 5 end,
    },
    {
        name = "Swift Feet",
        desc = "+25 move speed",
        apply = function(p) p.speed = p.speed + 25 end,
    },
    {
        name = "Long Reach",
        desc = "+15 swing reach",
        apply = function(p) p.reach = p.reach + 15 end,
    },
    {
        name = "Wide Arc",
        desc = "+20% swing arc",
        apply = function(p) p.swingArc = math.min(p.swingArc * 1.2, 2 * math.pi) end,
    },
    {
        name = "Heavy Hits",
        desc = "+100 knockback",
        apply = function(p) p.knockbackForce = p.knockbackForce + 100 end,
    },
    {
        name = "Quick Hands",
        desc = "15% faster swings",
        apply = function(p) p.swingDuration = p.swingDuration * 0.85 end,
    },
}

-- pick n different rewards at random
function Rewards.pick(n)
    local copy = {}
    for i, r in ipairs(Rewards.pool) do
        copy[i] = r
    end
    for i = #copy, 2, -1 do -- shuffle
        local j = love.math.random(i)
        copy[i], copy[j] = copy[j], copy[i]
    end
    local out = {}
    for i = 1, math.min(n, #copy) do
        out[i] = copy[i]
    end
    return out
end

return Rewards


