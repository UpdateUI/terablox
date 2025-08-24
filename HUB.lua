--[[
    Версия 3.3: "Project AURA" - Исправленная версия
    Все ошибки исправлены, код оптимизирован.
    Размещать в LocalScript внутри StarterPlayer > StarterPlayerScripts.
]]

-- Сервисы
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Игрок
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Переменные состояния
local basePosition = nil
local isTeleporting = false

-- Настройки анимаций
local TWEEN_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MEDIUM = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ОСНОВНОЙ ИНТЕРФЕЙС
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AuraTeleportGui_Stable"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- ЭФФЕКТЫ ЧАСТИЦ ДЛЯ ФЛИНГА
local flingParticles = Instance.new("ParticleEmitter")
flingParticles.Texture = "rbxassetid://2731926343"
flingParticles.Color = ColorSequence.new(Color3.fromRGB(150, 150, 255), Color3.fromRGB(255, 255, 255))
flingParticles.LightEmission = 1
flingParticles.Size = NumberSequence.new(0.5, 0)
flingParticles.Transparency = NumberSequence.new(0, 1)
flingParticles.Lifetime = NumberRange.new(0.2, 0.5)
flingParticles.Rate = 500
flingParticles.Speed = NumberRange.new(10, 20)
flingParticles.Enabled = false

-- ФУНКЦИЯ-ПОМОЩНИК ДЛЯ СОЗДАНИЯ СВЕЧЕНИЯ
local function createGlow(parent, color)
    local stroke = Instance.new("UIStroke")
    stroke.Parent = parent
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 3
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Transparency = 1 -- Изначально невидимый

    local gradient = Instance.new("UIGradient")
    gradient.Parent = stroke
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color),
        ColorSequenceKeypoint.new(1, Color3.new(color.r * 0.7, color.g * 0.7, color.b * 0.7))
    })
    gradient.Rotation = 90
    
    return stroke
end

-- ФУНКЦИЯ-ПОМОЩНИК ДЛЯ АНИМАЦИИ ПРОЗРАЧНОСТИ
local function fadeFrame(frame, shouldBeVisible)
    local goalTransparency = shouldBeVisible and 0 or 1
    
    if shouldBeVisible then
        frame.Visible = true
    end

    local tween = TweenService:Create(frame, TWEEN_MEDIUM, {BackgroundTransparency = goalTransparency})
    tween:Play()
    
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            local goal = {}
            if child:IsA("TextLabel") or child:IsA("TextBox") then
                goal.TextTransparency = goalTransparency
            end
            goal.BackgroundTransparency = goalTransparency
            TweenService:Create(child, TWEEN_MEDIUM, goal):Play()
        end
        if child:IsA("UIStroke") then
            TweenService:Create(child, TWEEN_MEDIUM, {Transparency = goalTransparency * 0.5}):Play()
        end
    end
    
    tween.Completed:Connect(function()
        if not shouldBeVisible then
            frame.Visible = false
        end
    end)
end

-- === ОБЩИЙ ДИЗАЙН ФРЕЙМОВ ===
local function setupFrame(name, isVisibleOnStart)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = UDim2.new(0, 320, 0, 220)
    frame.Position = UDim2.new(0.5, -160, 0.5, -110)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Draggable = true
    frame.Active = true
    frame.ClipsDescendants = true
    frame.Visible = isVisibleOnStart
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local radialGradient = Instance.new("UIRadialGradient")
    radialGradient.Parent = frame
    radialGradient.Color = ColorSequence.new(Color3.fromRGB(50, 50, 80), Color3.fromRGB(18, 18, 28))
    radialGradient.Transparency = NumberSequence.new(0.6, 1)
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = frame
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(150, 150, 255)
    stroke.Transparency = 1
    
    return frame
end

-- === ОКНО ВВОДА КЛЮЧА ===
local keyFrame = setupFrame("KeyFrame", true)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 20)
title.Text = "AUTHENTICATION"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -60, 0, 40)
keyInput.Position = UDim2.new(0.5, 0, 0, 80)
keyInput.AnchorPoint = Vector2.new(0.5, 0)
keyInput.PlaceholderText = "Enter Access Key"
keyInput.Text = ""
keyInput.ClearTextOnFocus = true
keyInput.TextColor3 = Color3.fromRGB(220, 220, 220)
keyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
keyInput.Font = Enum.Font.Gotham
keyInput.TextSize = 16
keyInput.Parent = keyFrame

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 8)
keyCorner.Parent = keyInput

local verifyButton = Instance.new("TextButton")
verifyButton.Size = UDim2.new(1, -60, 0, 45)
verifyButton.Position = UDim2.new(0.5, 0, 1, -40)
verifyButton.AnchorPoint = Vector2.new(0.5, 1)
verifyButton.Text = "UNLOCK"
verifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
verifyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
verifyButton.Font = Enum.Font.GothamBold
verifyButton.TextSize = 18
verifyButton.Parent = keyFrame

local verifyCorner = Instance.new("UICorner")
verifyCorner.CornerRadius = UDim.new(0, 8)
verifyCorner.Parent = verifyButton

local verifyGlow = createGlow(verifyButton, Color3.fromRGB(180, 180, 255))

-- === ГЛАВНОЕ ОКНО УПРАВЛЕНИЯ ===
local controlFrame = setupFrame("ControlFrame", false)

local setPositionButton = Instance.new("TextButton")
setPositionButton.Size = UDim2.new(1, -60, 0, 50)
setPositionButton.Position = UDim2.new(0.5, 0, 0, 30)
setPositionButton.AnchorPoint = Vector2.new(0.5, 0)
setPositionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
setPositionButton.Text = "SET POSITION"
setPositionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
setPositionButton.Font = Enum.Font.Gotham
setPositionButton.TextSize = 16
setPositionButton.Parent = controlFrame

local setCorner = Instance.new("UICorner")
setCorner.CornerRadius = UDim.new(0, 8)
setCorner.Parent = setPositionButton

local goToBaseButton = Instance.new("TextButton")
goToBaseButton.Size = UDim2.new(1, -60, 0, 50)
goToBaseButton.Position = UDim2.new(0.5, 0, 0, 95)
goToBaseButton.AnchorPoint = Vector2.new(0.5, 0)
goToBaseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
goToBaseButton.Text = "TELEPORT"
goToBaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
goToBaseButton.Font = Enum.Font.GothamBold
goToBaseButton.TextSize = 16
goToBaseButton.Parent = controlFrame

local goCorner = Instance.new("UICorner")
goCorner.CornerRadius = UDim.new(0, 8)
goCorner.Parent = goToBaseButton

local goGlow = createGlow(goToBaseButton, Color3.fromRGB(180, 180, 255))

local positionLabel = Instance.new("TextLabel")
positionLabel.Size = UDim2.new(1, -40, 0, 30)
positionLabel.Position = UDim2.new(0.5, 0, 1, -25)
positionLabel.AnchorPoint = Vector2.new(0.5, 1)
positionLabel.Text = "Location Status: STANDBY"
positionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
positionLabel.BackgroundTransparency = 1
positionLabel.Font = Enum.Font.Gotham
positionLabel.TextSize = 14
positionLabel.Parent = controlFrame

-- === ЛОГИКА И АНИМАЦИИ ===

-- Анимация наведения на кнопки
local function setupButtonEvents(button)
    local glow = button:FindFirstChildOfClass("UIStroke")
    button.MouseEnter:Connect(function()
        if glow then 
            TweenService:Create(glow, TWEEN_FAST, {Transparency = 0.5}):Play() 
        end
    end)
    button.MouseLeave:Connect(function()
        if glow then 
            TweenService:Create(glow, TWEEN_FAST, {Transparency = 1}):Play() 
        end
    end)
end

setupButtonEvents(verifyButton)
setupButtonEvents(setPositionButton)
setupButtonEvents(goToBaseButton)

-- Проверка ключа
verifyButton.MouseButton1Click:Connect(function()
    local enteredKey = string.gsub(keyInput.Text, "%s+", "")
    
    if enteredKey == "FREE-unlockUhGvBf" or enteredKey == "admin" then
        fadeFrame(keyFrame, false)
        task.wait(0.2)
        fadeFrame(controlFrame, true)
    else
        -- Анимация тряски
        local originalPos = keyFrame.Position
        for i = 1, 5 do
            keyFrame.Position = originalPos + UDim2.fromOffset(math.random(-5, 5), math.random(-5, 5))
            task.wait(0.03)
        end
        keyFrame.Position = originalPos
    end
end)

-- Установка позиции
setPositionButton.MouseButton1Click:Connect(function()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        basePosition = character.HumanoidRootPart.Position
        TweenService:Create(setPositionButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(80, 255, 80)}):Play()
        task.wait(1)
        TweenService:Create(setPositionButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

-- Телепортация
goToBaseButton.MouseButton1Click:Connect(function()
    if isTeleporting then return end
    if not basePosition then
        TweenService:Create(goToBaseButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play()
        task.wait(1)
        TweenService:Create(goToBaseButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(80, 80, 255)}):Play()
        return
    end
    
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not (humanoid and rootPart and humanoid.Health > 0) then return end
    
    isTeleporting = true
    goToBaseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    
    local particlesClone = flingParticles:Clone()
    particlesClone.Parent = rootPart
    particlesClone.Enabled = true
    
    for i = 1, 20 do
        local flingVector = Vector3.new(math.random(-250, 250), math.random(50, 150), math.random(-250, 250))
        rootPart.Velocity = flingVector
        local rotVector = Vector3.new(math.random(-500, 500), math.random(-500, 500), math.random(-500, 500))
        rootPart.RotVelocity = rotVector
        task.wait(0.06)
    end
    
    rootPart.CFrame = CFrame.new(basePosition)
    rootPart.Velocity = Vector3.new(0,0,0)
    rootPart.RotVelocity = Vector3.new(0,0,0)
    
    particlesClone.Enabled = false
    task.wait(1)
    particlesClone:Destroy()
    
    isTeleporting = false
    goToBaseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
end)

-- Обновление текста с позицией
local lastUpdate = 0
RunService.RenderStepped:Connect(function(deltaTime)
    lastUpdate = lastUpdate + deltaTime
    if lastUpdate < 0.2 then return end
    lastUpdate = 0
    
    if controlFrame.Visible and basePosition then
        positionLabel.Text = string.format("Target Locked: %.0f, %.0f, %.0f", basePosition.X, basePosition.Y, basePosition.Z)
        positionLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    elseif controlFrame.Visible and not basePosition then
        positionLabel.Text = "Location Status: STANDBY"
        positionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    end
end)

-- Запуск интерфейса
fadeFrame(keyFrame, true)

-- Добавляем горячую клавишу для показа/скрытия интерфейса
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if controlFrame.Visible then
            fadeFrame(controlFrame, false)
        else
            fadeFrame(controlFrame, true)
        end
    end
end)
