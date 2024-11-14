local GRID_WIDTH = 80
local GRID_HEIGHT = 60
local CELL_SIZE = 10
local FISH_BREED_TIME = 3
local SHARK_BREED_TIME = 3 -- 10
local SHARK_ENERGY = 5

local UPDATE_INTERVAL = 0.25
local timer = 0

local BUTTON_HEIGHT = 30
local isPaused = false

local grid = {}
local nextGrid = {}

local buttons = {}

function love.load()
  -- Initialize rng
  math.randomseed(os.time())

  for x = 1, GRID_WIDTH do
    grid[x] = {}
    nextGrid[x] = {}
    for y = 1, GRID_HEIGHT do
      -- seed ocean with fish and sharks
      local r = math.random()
      if r < 0.2 then
        grid[x][y] = { type = "fish", breed = 0 }
      elseif r < 0.30 then
        grid[x][y] = { type = "shark", breed = 0, energy = SHARK_ENERGY }
      else
        grid[x][y] = nil
      end
      nextGrid[x][y] = nil
    end
  end
end

function love.mousepressed(x, y, button, istouch, presses)
  local clickedLabel = ""
  if button == 1 then -- left click
    for _, btn in ipairs(buttons) do
      if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
        clickedLabel = btn.label        
      end
    end
  end

  if clickedLabel == "PAUSE" then
    isPaused = true
  elseif clickedLabel == "PLAY" then
    isPaused = false  
  end
end

function love.update(dt)
  if isPaused then
    return
  end

  timer = timer + dt

  if timer < UPDATE_INTERVAL then
    return
  end

  timer = 0

  for x = 1, GRID_WIDTH do
    for y = 1, GRID_HEIGHT do
      nextGrid[x][y] = nil
    end
  end

  -- Update the simulation
  for x = 1, GRID_WIDTH do
    for y = 1, GRID_HEIGHT do
      if grid[x][y] then
        updateCell(x, y)
      end
    end
  end

  grid, nextGrid = nextGrid, grid
end

function love.draw()
  -- love.graphics.setColor(0.3, 0.3, 0.3)
  -- love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), BUTTON_)
  -- love.graphics.setColor(1, 1, 1)
  local pauseText = isPaused and "PLAY" or "PAUSE"
  -- love.graphics.print(pauseText, 10, 0)
  -- local fps = love.timer.getFPS()
    
  drawTopBar()

  buttons = {}
  roundedButton(pauseText, 5, textWidth("PAUSE") + 20, 5, 0.3, 0.3, 0.3)

  love.graphics.translate(0, BUTTON_HEIGHT + 10)
  
  for x = 1, GRID_WIDTH do
    for y = 1, GRID_HEIGHT do
      if not grid[x][y] then
        love.graphics.setColor(0, 0, 1) 
      elseif grid[x][y].type == "fish" then
        love.graphics.setColor(0, 1, 0) 
      elseif grid[x][y].type == "shark" then
        love.graphics.setColor(1, 0, 0)
      end
      love.graphics.rectangle("fill", (x-1)*CELL_SIZE, (y-1)*CELL_SIZE, CELL_SIZE, CELL_SIZE)
    end
  end
end

function textWidth(text)
  local font = love.graphics.getFont()
  return font:getWidth(text)
end

function roundedButton(text, x, buttonWidth, radius, r, g, b)
  local y = 5
  local font = love.graphics.getFont()
  local textWidth = font:getWidth(text)
  local textHeight = font:getHeight()
  
  local btn = { x=x, y=y, width=buttonWidth, height=BUTTON_HEIGHT, label=text }
  table.insert(buttons, btn)
  love.graphics.setColor(r, g, b)
  love.graphics.rectangle("fill", x + radius, y + radius, buttonWidth - (radius * 2), BUTTON_HEIGHT - radius * 2)
	love.graphics.rectangle("fill", x + radius, y, buttonWidth - (radius * 2), radius)
	love.graphics.rectangle("fill", x + radius, y + BUTTON_HEIGHT - radius, buttonWidth - (radius * 2), radius)
	love.graphics.rectangle("fill", x, y + radius, radius, BUTTON_HEIGHT - (radius * 2))
	love.graphics.rectangle("fill", x + buttonWidth - radius, y + radius, radius, BUTTON_HEIGHT - (radius * 2))
	
	love.graphics.arc("fill", x + radius, y + radius, radius, math.rad(-180), math.rad(-90))
	love.graphics.arc("fill", x + buttonWidth - radius , y + radius, radius, math.rad(-90), math.rad(0))
	love.graphics.arc("fill", x + radius, y + BUTTON_HEIGHT - radius, radius, math.rad(-180), math.rad(-270))
	love.graphics.arc("fill", x + buttonWidth - radius , y + BUTTON_HEIGHT - radius, radius, math.rad(0), math.rad(90))

  love.graphics.setColor(1, 1, 1)  
  local textX = x + (buttonWidth - textWidth) / 2
  local textY = y + (BUTTON_HEIGHT - textHeight) / 2
  love.graphics.print(text, textX, textY)
end

function drawTopBar()
  love.graphics.setColor(0.0, 0.0, 0.0)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), BUTTON_HEIGHT + 10)
end

function updateCell(x, y)
  local cell = grid[x][y]
  if not cell then return end

  local adj = getAdjCells(x, y)
  local emptySpaces = {}
  local fishSpaces = {}

  for _, pos in ipairs(adj) do
    if not grid[pos.x][pos.y] then
      table.insert(emptySpaces, pos)
    elseif grid[pos.x][pos.y].type == "fish" and cell.type == "shark" then    
      table.insert(fishSpaces, pos)
    end
  end

  if cell.type == "shark" then
    updateShark(x, y, cell, emptySpaces, fishSpaces)
  else
    updateFish(x, y, cell, emptySpaces)
  end
end

function getAdjCells(x, y)
  local adj = {}
  local dirs = {
    {x=-1, y=0}, {x=1, y=0}, {x=0, y=-1}, {x=0, y=1}
  }

  for _, dir in ipairs(dirs) do
    local dx = x + dir.x
    local dy = y + dir.y
    
    -- Wrap around edges (the world is a doughnut)
    if dx < 1 then
      dx = GRID_WIDTH
    elseif dx > GRID_WIDTH then 
      dx = 1 
    end
    if dy < 1 then 
      dy = GRID_HEIGHT
    elseif dy > GRID_HEIGHT then 
      dy = 1 
    end

    table.insert(adj, {x=dx, y=dy})
  end

  return adj
end

function updateFish(x, y, fish, emptySpaces)
  if #emptySpaces == 0 then
    nextGrid[x][y] = fish
    return
  end

  local newPos = emptySpaces[math.random(#emptySpaces)]
  fish.breed = fish.breed + 1

  if fish.breed >= FISH_BREED_TIME then
    nextGrid[x][y] = { type = "fish", breed = 0}
    fish.breed = 0
  end

  nextGrid[newPos.x][newPos.y] = fish
end

function updateShark(x, y, shark, emptySpaces, fishSpaces)
  shark.energy = shark.energy - 1
  
  -- shark does if out of energy
  if shark.energy <= 0 then
    return
  end

  if #fishSpaces > 0 then
    local newPos = fishSpaces[math.random(#fishSpaces)]
    shark.energy = shark.energy + SHARK_ENERGY
    shark.breed = shark.breed + 1

    if shark.breed >= SHARK_BREED_TIME then
      nextGrid[x][y] = { type = "shark", energy = SHARK_ENERGY, breed = 0}
      shark.breed = 0
    end

    nextGrid[newPos.x][newPos.y] = shark
    return
  end

  -- move to empty space if no fish around
  if #emptySpaces > 0 then
    local newPos = emptySpaces[math.random(#emptySpaces)]
    shark.breed = shark.breed + 1

    if shark.breed >= SHARK_BREED_TIME then
      nextGrid[x][y] = { type = "shark", energy = SHARK_ENERGY, breed = 0}
      shark.breed = 0
    end

    nextGrid[newPos.x][newPos.y] = shark
  else
    nextGrid[x][y] = shark
  end
end
