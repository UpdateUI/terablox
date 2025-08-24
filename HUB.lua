--[[
    Версия 3.2: "Project AURA" - Silent & Stable
    Исправлена ошибка запуска, скрипт сделан более надежным. Все звуки удалены.
    Размещать в LocalScript внутри StarterPlayer > StarterPlayerScripts.
]]

-- Сервисы
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "AuraTeleportGui_Stable"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

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
    local stroke = Instance.new("UIStroke", parent)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 3
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Transparency = 1 -- Изначально невидимый

    local gradient = Instance.new("UIGradient", stroke)
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
            TweenService:Create(child, TWEEN_MEDIUM, {BackgroundTransparency = goalTransparency, TextTransparency = goalTransparency}):Play()
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
    local frame = Instance.new("Frame", screenGui)
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
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    
    local radialGradient = Instance.new("UIRadialGradient", frame)
    radialGradient.Color = ColorSequence.new(Color3.fromRGB(50, 50, 80), Color3.fromRGB(18, 18, 28))
    radialGradient.Transparency = NumberSequence.new(0.6, 1)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(150, 150, 255)
    stroke.Transparency = 1
    
    return frame
end

-- === ОКНО ВВОДА КЛЮЧА ===
local keyFrame = setupFrame("KeyFrame", true)

local title = Instance.new("TextLabel", keyFrame)
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 20)
title.Text = "AUTHENTICATION"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1

local keyInput = Instance.new("TextBox", keyFrame)
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
Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 8)

local verifyButton = Instance.new("TextButton", keyFrame)
verifyButton.Size = UDim2.new(1, -60, 0, 45)
verifyButton.Position = UDim2.new(0.5, 0, 1, -40)
verifyButton.AnchorPoint = Vector2.new(0.5, 1)
verifyButton.Text = "UNLOCK"
verifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
verifyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
verifyButton.Font = Enum.Font.GothamBold
verifyButton.TextSize = 18
Instance.new("UICorner", verifyButton).CornerRadius = UDim.new(0, 8)
local verifyGlow = createGlow(verifyButton, Color3.fromRGB(180, 180, 255))

-- === ГЛАВНОЕ ОКНО УПРАВЛЕНИЯ ===
local controlFrame = setupFrame("ControlFrame", false)

local setPositionButton = Instance.new("ImageButton", controlFrame)
setPositionButton.Size = UDim2.new(1, -60, 0, 50)
setPositionButton.Position = UDim2.new(0.5, 0, 0, 30)
setPositionButton.AnchorPoint = Vector2.new(0.5, 0)
setPositionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
setPositionButton.Image = "rbxassetid://3926307971"
setPositionButton.ImageColor3 = Color3.fromRGB(200, 200, 200)
setPositionButton.ScaleType = Enum.ScaleType.Fit
Instance.new("UICorner", setPositionButton).CornerRadius = UDim.new(0, 8)

local goToBaseButton = Instance.new("ImageButton", controlFrame)
goToBaseButton.Size = UDim2.new(1, -60, 0, 50)
goToBaseButton.Position = UDim2.new(0.5, 0, 0, 95)
goToBaseButton.AnchorPoint = Vector2.new(0.5, 0)
goToBaseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
goToBaseButton.Image = "rbxassetid://3926305904"
goToBaseButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
goToBaseButton.ScaleType = Enum.ScaleType.Fit
Instance.new("UICorner", goToBaseButton).CornerRadius = UDim.new(0, 8)
local goGlow = createGlow(goToBaseButton, Color3.fromRGB(180, 180, 255))

local positionLabel = Instance.new("TextLabel", controlFrame)
positionLabel.Size = UDim2.new(1, -40, 0, 30)
positionLabel.Position = UDim2.new(0.5, 0, 1, -25)
positionLabel.AnchorPoint = Vector2.new(0.5, 1)
positionLabel.Text = "Location Status: STANDBY"
positionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
positionLabel.BackgroundTransparency = 1
positionLabel.Font = Enum.Font.Gotham
positionLabel.TextSize = 14

-- === ЛОГИКА И АНИМАЦИИ ===

-- Анимация наведения на кнопки
local function setupButtonEvents(button)
    local glow = button:FindFirstChildOfClass("UIStroke")
    button.MouseEnter:Connect(function()
        if glow then TweenService:Create(glow, TWEEN_FAST, {Transparency = 0.5}):Play() end
    end)
    button.MouseLeave:Connect(function()
        if glow then TweenService:Create(glow, TWEEN_FAST, {Transparency = 1}):Play() end
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
    
    particlesClone:Emit(0)
    task.wait(1)
    particlesClone:Destroy()
    
    isTeleporting = false
    goToBaseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
end)

-- Обновление текста с позицией
RunService.RenderStepped:Connect(function()
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