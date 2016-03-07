-- AUTHOR: Lakshay Akula

-- Load some default values for our rectangle.
function love.load() 

    -- set 1 m to 64 px
    love.physics.setMeter(64) 
    -- create world with vertical gravity of 0
    gravity = 0
    world = love.physics.newWorld(0, gravity*64, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    --  Size constants
    windowWidth  = 650
    windowHeight = 650
    border = 25
    sideLength = 100

    -- The table we pick our colors from
    -- Source: http://www.color-hex.com/color-palette/15968
    colors = {{235,189,240}, {236,179,179}, {247,251,184}, {189,241,249}, {249,186,253}}
    -- Initialize color count to 0
    colorCount = 0

    -- A table to hold all of our game objects
    objects = {}

    -- Creating the border
    initBorder()

    -- Creating the player
    initPlayer()

    -- Create a table of enemies
    objects.enemies = {}
    enemyNum = 0
    -- Add enemy to enemies
    addEnemy()
    
    --initial graphics setup
    love.graphics.setBackgroundColor(230, 250, 250) --set the background color to a nice blue
    love.window.setMode(650, 650) --set the window dimensions to 650 by 650 with no fullscreen, vsync on, and no antialiasing

    -- These tables contain things to delete/add
    remFixtures = {}
    toAdd       = {}
end

function love.update(dt)
    world:update(dt) --this puts the world into motion
 
  --here we are going to create some keyboard events
  if love.keyboard.isDown("right") then --press the right arrow key to push the ball to the right
    objects.player.body:applyForce(400, 0)
  elseif love.keyboard.isDown("left") then --press the left arrow key to push the ball to the left
    objects.player.body:applyForce(-400, 0)
  elseif love.keyboard.isDown("up") then --press the up arrow key to set the ball in the air
    objects.player.body:applyForce(0, -400)
  elseif love.keyboard.isDown("down") then 
    objects.player.body:applyForce(0, 400)
  elseif love.keyboard.isDown("r") then
    objects.player.body:setPosition(650/2, 650/2)
    objects.player.body:setLinearVelocity(0, 0) --we must set the velocity to zero to prevent a potentially large velocity generated by the change in position
    objects.player.body:setAngularVelocity(0)
  end

    cleanUp()
    addEars()
end

function love.draw()

    -- love.graphics.translate(objects.player.body:getX(), objects.player.body:getY())

    for key,fixture in ipairs(objects.player.body:getFixtureList()) do
        local color = getColor(fixture:getGroupIndex())
        love.graphics.setColor(color)
        love.graphics.polygon("fill", objects.player.body:getWorldPoints(fixture:getShape():getPoints())) 
    end

    for key,enemy in ipairs(objects.enemies) do
        for key,fixture in ipairs(enemy.body:getFixtureList()) do
            local shape = fixture:getShape()
            local color = getColor(fixture:getGroupIndex())
            love.graphics.setColor(color)
            love.graphics.polygon("fill", enemy.body:getWorldPoints(shape:getPoints())) 
        end
    end
end

function initBorder()
    objects.border = {}

    -- First ground and ceiling
    objects.border.ground = {}
    objects.border.ground.body = love.physics.newBody(world, windowWidth/2, windowHeight-border/2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    objects.border.ground.shape = love.physics.newRectangleShape(windowWidth, border) --make a rectangle with a width of 650 and a height of 25
    objects.border.ground.fixture = love.physics.newFixture(objects.border.ground.body, objects.border.ground.shape) --attach shape to body
    objects.border.ground.fixture:setUserData(-1)


    objects.border.ceiling = {}
    objects.border.ceiling.body = love.physics.newBody(world, windowWidth/2, border/2)
    objects.border.ceiling.shape = love.physics.newRectangleShape(windowWidth, border) --make a rectangle with a width of 650 and a height of 25
    objects.border.ceiling.fixture = love.physics.newFixture(objects.border.ceiling.body, objects.border.ceiling.shape) --attach shape to body    
    objects.border.ceiling.fixture:setUserData(-1)


    -- Next both walls
    objects.border.leftwall = {}
    objects.border.leftwall.body = love.physics.newBody(world, border/2, windowHeight/2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    objects.border.leftwall.shape = love.physics.newRectangleShape(border, windowHeight - 2*border) --make a rectangle with a width of 650 and a height of 25
    objects.border.leftwall.fixture = love.physics.newFixture(objects.border.leftwall.body, objects.border.leftwall.shape) --attach shape to body
    objects.border.leftwall.fixture:setUserData(-1)

    objects.border.rightwall = {}
    objects.border.rightwall.body = love.physics.newBody(world, windowWidth-border/2, windowHeight/2)
    objects.border.rightwall.shape = love.physics.newRectangleShape(border, windowHeight - 2*border) --make a rectangle with a width of 650 and a height of 25
    objects.border.rightwall.fixture = love.physics.newFixture(objects.border.rightwall.body, objects.border.rightwall.shape) --attach shape to body
    objects.border.rightwall.fixture:setUserData(-1)
end

-- The player contains several triangles. Each of which includes a color, 
--- physics.shape and area . When we initialize, we give the player just one eq
-- triangle of sizeLength.
function initPlayer()
    local centroidLength = sideLength/(3^(1/2))

    objects.player = {}

    -- Place player in center. Set to "dynamic" so it can move
    local pos_x = windowWidth/2
    local pos_y = windowHeight/2
    objects.player.body = love.physics.newBody(world, pos_x, pos_y, "dynamic")

    -- Add one triangle at center to triangles
    objects.player.triangles = {}
    objects.player.triangles[1] = {}
    objects.player.triangles[1].color = {}
    objects.player.triangles[1].color = {50, 50, 50}

    local ax = 0
    local ay = centroidLength

    local bx = -sideLength/2
    local by = -centroidLength/2

    local cx = sideLength/2
    local cy = -centroidLength/2

    objects.player.triangles[1].shape = love.physics.newPolygonShape(ax, ay, bx, by, cx, cy)
    objects.player.triangles[1].area  = calculateArea(ax, ay, bx, by, cx, cy)

    -- Fix triangle to player with density of 1
    objects.player.fixture = love.physics.newFixture(objects.player.body,
                                                     objects.player.triangles[1].shape, 1)

    objects.player.fixture:setGroupIndex(colorCount)
    colorCount = colorCount + 1

    -- local ear = love.physics.newPolygonShape(ax, ay, bx, by, -20, 46.188)
    -- love.physics.newFixture(objects.player.body, ear, 1)

    for i, fixture in ipairs(objects.player.body:getFixtureList()) do
        fixture:setUserData(0)
    end
end

-- An enemy is like a player, except that their location
-- is randomized.
function addEnemy()
    -- Increment which enemy this is
    enemyNum = enemyNum + 1

    local enemy = {}
    local length = sideLength*0.8
    local centroidLength = length/(3^(1/2))

    -- Place enemy randomly on screen
    local pos_x = love.math.random(length, windowWidth - length)
    local pos_y = love.math.random(length, windowHeight - length)
    enemy.body = love.physics.newBody(world, pos_x, pos_y)

    local ax = 0
    local ay = centroidLength

    local bx = -length/2
    local by = -centroidLength/2

    local cx = length/2
    local cy = -centroidLength/2

    local shape = love.physics.newPolygonShape(ax, ay, bx, by, cx, cy)

    -- Fix triangle to enemy with density of 1
    enemy.fixture = love.physics.newFixture(enemy.body, shape, 1)
    enemy.fixture:setGroupIndex(colorCount)
    colorCount = colorCount + 1
    
    enemy.fixture:setUserData(enemyNum)
    objects.enemies[enemyNum] = enemy
end

-- Deletes fixtures in remFixtures
-- TODO: The fixture is still drawn on the screen
function cleanUp()
    for i, fixture in ipairs(remFixtures) do
        if (fixture ~= nil) then
            fixture:destroy()
            table.remove(remFixtures, i)
            addEnemy()
        end
    end
end

function addEars()
    for i, ear in ipairs(toAdd) do
        table.remove(toAdd, i)
        local fix = love.physics.newFixture(objects.player.body, ear, 1) 
        fix:setUserData(0)
        fix:setGroupIndex(colorCount)
        colorCount = colorCount + 1
    end
end

function beginContact(a, b, coll)

    -- Find who collided with whom
    local a_key = a:getUserData()
    local b_key = b:getUserData()

    if ((a_key == 0) and (b_key > 0)) then
        local player, enemy = a, b
        eat(a, b, coll)
    elseif ((a_key > 0) and (b_key == 0)) then
        eat(b, a, coll)
    end

end

function eat(predator, prey, coll) 

    local predBody  = predator:getBody()
    local predShape = predator:getShape()

    local preyBody  = prey:getBody()
    local preyShape = prey:getShape()

    -- Calculate prey's area
    local area = fixtureArea(prey)

    -- Get predator vertices
    local v1, v2, v3 = {}, {}, {}
    v1.x, v1.y, v2.x, v2.y, v3.x, v3.y = predBody:getWorldPoints(predShape:getPoints())
    local vertices = {v1, v2, v3}

    -- To add an ear to a, we need to find the vertices of the ear
    -- we want to add.

    -- Find point of collision
    local col = {}
    col.x, col.y = coll:getPositions()
        
    -- Find two nearest vertices in fixture predator
    local new_v1, new_v2 = findTwoNearest(vertices, col)

    -- Change the new vertices to local coordinates relative to predator
    new_v1.x, new_v1.y = predator:getBody():getLocalPoint(new_v1.x, new_v1.y)
    new_v2.x, new_v2.y = predator:getBody():getLocalPoint(new_v2.x, new_v2.y)

    -- Find third vertex that provides the necessary area
    local new_v3 = findEarVertex(new_v1, new_v2, area, predator)

    print(new_v3.x .. ", " .. new_v3.y)

    local ear = love.physics.newPolygonShape(new_v1.x, new_v1.y, new_v2.x, new_v2.y, new_v3.x, new_v3.y)

    table.insert(remFixtures, prey)
    table.insert(toAdd, ear)
end

function fixtureArea(fixture)
    return calculateArea(fixture:getShape():getPoints())
end

function findTwoNearest(points, target)

    local v1, v2 = points[1], points[2]
    
    local dist = 0
    
    local minDist  = 0x7FFFFF -- Basically INT_MAX
    local min2Dist = 0x7FFFFF -- Basically INT_MAX

    for i, point in ipairs(points) do 
        dist = distance(point, target)
        if (dist < minDist) then

            min2Dist = minDist
            minDist = dist
            v2 = v1
            v1 = point

        elseif (dist < min2Dist) then 

            min2Dist = dist
            v2 = point
        
        end
    end

    return v1, v2
end

function math.dist(x1,y1,x2,y2)
    return ((x2-x1)^2+(y2-y1)^2)^0.5
end


function distance(p1, p2)
    return math.dist(p1.x, p1.y, p2.x, p2.y)
end

function findEarVertex(p1, p2, area, fixture)

    local base   = distance(p1, p2)
    local height = (2*area / base) 

    local midPt  = {}
    midPt.x = (p1.x + p2.x)/2
    midPt.y = (p1.y + p2.y)/2

    -- Now we need to find the perp bisector of the triangle
    local perp = {}
    perp.x, perp.y = (p1.x - p2.x), (p1.y - p2.y)
    perp.x, perp.y = normalize(perp)
    perp.x, perp.y = height*perp.x, height*perp.y
    
    choice1 = {}
    choice1.x, choice1.y = midPt.x + perp.y, midPt.y - perp.x

    choice2 = {}
    choice2.x, choice2.y = midPt.x - perp.y, midPt.y + perp.x

    if (fixture:testPoint(fixture:getBody():getWorldPoint(choice1.x, choice1.y))) then
        return choice2
    else
        return choice1
    end
end

function addEar(body, v1, v2, v3)
    local ear = love.physics.newPolygonShape(v1.x, v1.y, v2.x, v2.y, v3.x, v3.y)
    love.physics.newFixture(body, ear, 1)
end

function normalize(vector)
    mag = magnitude(vector)
    return vector.x/mag, vector.y/mag
end

function magnitude(vector)
    return math.sqrt(vector.x^2 + vector.y^2)
end

function addEar(fixture, area)

end
 
function endContact(a, b, coll)
 
end
 
function preSolve(a, b, coll)
 
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
 
end

function calculateArea(ax, ay, bx, by, cx, cy)
    return math.abs((ax*(by - cy) + bx*(cy - ay) + cx*(ay - by))/2)
end

function getColor(index)
    return colors[(index%5) + 1]
end


