do -- uAlert v0.1
  uAlert = {}
  local uLayer
  local AlertList = {}
  local active = false
  local newSprite
  local drawSprite
  local setRect

  local function lerp(a,b,m)
    return m*b + (1-m)*a
  end
  
  function uAlert.initialize()
    uLayer = tolua(game.level.newArtLayer(0))
    if not uLayer then
      player.alert("uAlert failed to initialize due to player settings. Please turn on art layers.")
      return false
    end
    setRect = tolua(uLayer.setRect)
    drawSprite = tolua(uLayer.drawSprite)
    newSprite = tolua(game.level.newSprite)
    uLayer.layerNum = 3
    active = true
    return true
  end

  uAlert.pos = {x = 575,y = 60}
  uAlert.stiffness = 0.25
  uAlert.spacing = 10

  -- The following parameters only apply to new alerts.
  uAlert.size = {w = 80, h = 60}
  uAlert.roundness = 6
  uAlert.thickness = 2
  uAlert.outColor = 0x4969D2
  uAlert.inColor = 0xB6E7EB
  uAlert.textColor = 0x071E6B
  uAlert.textSize = 12
  uAlert.alpha = .95 -- Value from 0 to 1

  function uAlert.add(text,time,fadeTime)
    if not active then return end
    local u = {
      text = text, 
      startTime = tolua(game.elapsedMS), 
      time = time,
      fadeTime = fadeTime,
      x = uAlert.pos.x, y = uAlert.pos.y - 200,
      w = uAlert.size.w, h = uAlert.size.h,
      targetX = -1, targetY = -1 -- Will be set by lua when ticking.
    }
    local sprite = newSprite()
    sprite.beginFill(uAlert.inColor + 0xFF000000)
    sprite.lineStyle(uAlert.outColor + 0xFF000000,uAlert.thickness,toobject({}))
    sprite.drawRoundRect(0,0,uAlert.size.w,uAlert.size.h,uAlert.roundness,uAlert.roundness)
    sprite.endFill()
    sprite.addText(text,2,0,uAlert.textColor+0xFF000000,uAlert.textSize)
    sprite.alpha = uAlert.alpha
    u.sprite = sprite
    table.insert(AlertList,1,u)
  end

  local function dropOld(time)
    for i=#AlertList,1,-1 do
      local u = AlertList[i]
      local t = time - u.startTime
      if t > u.time then
        table.remove(AlertList,i)
      end
    end
  end

  local function setTargets()
    local yAt = uAlert.pos.y
    for i=1,#AlertList do
      local u = AlertList[i]
      u.targetX = uAlert.pos.x
      u.targetY = yAt
      yAt = yAt + u.h + uAlert.spacing
    end
  end

  local function setPos()
    local xMin = math.huge
    local xMax = -math.huge
    local yMin = math.huge
    local yMax = -math.huge
    for i=1,#AlertList do
      local u = AlertList[i]
      u.x = lerp(u.x,u.targetX,uAlert.stiffness)
      u.y = lerp(u.y,u.targetY,uAlert.stiffness)
      if u.x < xMin then xMin = u.x end
      if u.y < yMin then yMin = u.y end
      if (u.x + u.w) > xMax then xMax = (u.x + u.w) end
      if (u.y + u.h) > yMax then yMax = (u.y + u.h) end
    end
    return {xMin,xMax,yMin,yMax}
  end

  local function drawAlerts(time,oldBox)
    setRect(oldBox[1]-uAlert.thickness*2,oldBox[3]-uAlert.thickness*2,oldBox[2]-oldBox[1]+1 + uAlert.thickness*4,oldBox[4]-oldBox[3]+1 + uAlert.thickness*4,0)
    for i=1,#AlertList do
      local u = AlertList[i]
      local t = u.time - (time - u.startTime)
      if t < u.fadeTime then
        u.sprite.alpha = lerp(0,uAlert.alpha,t/(u.fadeTime))
      end
      drawSprite(u.sprite,u.x,u.y)
    end
  end

  local oldBox = {0,0,0,0}
  function uAlert.tick()
    if not active then return end
    local time = tolua(game.elapsedMS)
    local box
    if #AlertList >= 1 then
      dropOld(time)
      setTargets()
      box = setPos()
    end
    drawAlerts(time,oldBox)
    if box then
      oldBox = box
    end
  end

end
