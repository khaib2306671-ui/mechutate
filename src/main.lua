--helper stuffs for rewards.lua
local HEAL_FRACTION = 0.15
-- reward choice cards
local CHOICE_COUNT = 3
local CARD_W, CARD_H, CARD_GAP = 260, 170, 40

-- normal node: HEAL_FRACTION, rest: double that, drop point: full heal
local function healForNode(node)
    local name = node.type.name
    if name == "drop point" then
        player:heal(player.maxHealth)
    elseif name == "rest" then
        player:heal(player.maxHealth * HEAL_FRACTION * 2)
    else
        player:heal(player.maxHealth * HEAL_FRACTION)
    end
end

local function startBattle(node)
    waves = Waves.new(board, node.waves)
    player.x, player.y = board.sizex / 2, board.sizey / 2
    player.swinging = nil
    state = "battle"
end

-- called whenever the player arrives at a node that hasn't been cleared
function enterNode(node)
    healForNode(node)
    if node.type.name == "drop point" then
        choices = Rewards.pick(CHOICE_COUNT)
        state = "choose"
    else
        startBattle(node)
    end
end

function chooseReward(i)
    pendingReward = choices[i]
    choices = nil
    startBattle(map.current)
end

local function cardRect(i)
    local n = #choices
    local total = n * CARD_W + (n - 1) * CARD_GAP
    local x = (screenx - total) / 2 + (i - 1) * (CARD_W + CARD_GAP)
    local y = screeny / 2 - CARD_H / 2
    return x, y, CARD_W, CARD_H
end

function cardAt(mx, my)
    for i = 1, #choices do
        local x, y, w, h = cardRect(i)
        if mx >= x and mx <= x + w and my >= y and my <= y + h then
            return i
        end
    end
end


function love.load()
    icon = love.graphics.newImage("icon.png")

    Board = require "board"
    Classes = require "classes"
    Player = require "player"
    Map = require "map"
    Waves = require "waves"
    Rewards = require "rewards"
    screenx = love.graphics.getWidth()
    screeny = love.graphics.getHeight()

    board = Board:new(1600, screenx, screeny)
    waves = Waves.new(board)
    player = Player:new()


    map = Map.new(200)   -- number of nodes
    waves = Waves.new(board, map.current.waves)

    pendingReward = nil
    rewardMessage, rewardTimer = nil, 0

    enterNode(map.current)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
    if state == "gameover" and key == "r" then
        love.load()
    end
    if state == "choose" then
        local i = tonumber(key)
        if i and choices[i] then
            chooseReward(i)
        end
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then 
        return
    end
    if state == "map" then
        local node = map:mousepressed(x, y)
        if node then
            map.current = node
            if not node.cleared then
                enterNode(node)
            end
        end
    elseif state == "choose" then
        local i = cardAt(x, y)
        if i then
            chooseReward(i)
        end
    end
end

function love.update(dt)
    board:update(dt)    -- nothing to update (at least not yet)
    if state == "battle" then
        player:update(dt, board)
        waves:update(dt, player)
        if player:isDead() then
            state = "gameover"
        elseif waves.done then
            map.current.cleared = true
            if pendingReward then
                pendingReward.apply(player)
                rewardMessage = "Reward received: " .. pendingReward.name .. " (" .. pendingReward.desc .. ")"
                rewardTimer = 3
                pendingReward = nil
            end
            state = "map"
        elseif state == "map" then
            map:update(dt)
            rewardTimer = math.max(0, rewardTimer - dt)
        end
    end
end

local function drawHealth(x, y)
    local w, h = 200, 16
    local p = player.health / player.maxHealth
    love.graphics.push("all")
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0.85, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, w * p, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.print(math.ceil(player.health) .. " / " .. player.maxHealth, x + w + 10, y + 1)
    love.graphics.pop()
end

local function drawChoices()
    love.graphics.push("all")
    love.graphics.printf("Drop point: choose a reward", 0, screeny / 2 - CARD_H / 2 - 110, screenx, "center")
    love.graphics.setColor(0.75, 0.75, 0.75)
    love.graphics.printf("You'll receive it after clearing all " .. map.current.waves .. " waves",
        0, screeny / 2 - CARD_H / 2 - 60, screenx, "center")

    local mx, my = love.mouse.getPosition()
    local hovered = cardAt(mx, my)
    for i, r in ipairs(choices) do
        local x, y, w, h = cardRect(i)
        if i == hovered then
            y = y - 6 -- lift the hovered card a bit
        end
        love.graphics.setColor(0.15, 0.12, 0.2)
        love.graphics.rectangle("fill", x, y, w, h, 10, 10)
        love.graphics.setColor(0.7, 0.3, 0.8, i == hovered and 1 or 0.6) -- drop point purple
        love.graphics.setLineWidth(i == hovered and 4 or 2)
        love.graphics.rectangle("line", x, y, w, h, 10, 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(r.name, x + 15, y + 30, w - 30, "center")
        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.printf(r.desc, x + 15, y + 80, w - 30, "center")
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("[" .. i .. "]", x, y + h - 30, w, "center")
    end
    love.graphics.pop()
end

function love.draw()
    if state == "battle" then
        board:draw()
        player:draw()
        waves:draw(player.scale)
        love.graphics.print("Wave " .. waves.wave .. " / " .. waves.maxWaves, 10, 10)
        drawHealth(10, 30)
        if pendingReward then
            love.graphics.print("Reward on clear: " .. pendingReward.name, 10, 54)
        end
    elseif state == "choose" then
        drawChoices()
        drawHealth(10, 10)
    elseif state == "map" then
        map:draw()
        drawHealth(10, 10)
        if rewardTimer > 0 then
            love.graphics.push("all")
            love.graphics.setColor(1, 1, 1, math.min(1, rewardTimer))
            love.graphics.printf(rewardMessage, 0, screeny - 80, screenx, "center")
            love.graphics.pop()
        end
    else
        love.graphics.push("all")
        love.graphics.printf("You died\n\nPress R to restart", 0, screeny / 2 - 60, screenx, "center")
        love.graphics.pop()
    end
end
