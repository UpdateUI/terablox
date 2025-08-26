-- Сервисы
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Переменные
local player = Players.LocalPlayer
local screenGui = script.Parent

-- # НАСТРОЙКИ ДИЗАЙНА #
local THEME = {
    Title = "BlackHorse",
    MainColor = Color3.fromRGB(30, 32, 36),
    HeaderColor = Color3.fromRGB(25, 27, 30),
    ButtonColor = Color3.fromRGB(48, 51, 58),
    TextColor = Color3.fromRGB(230, 230, 230),
    AccentColor = Color3.fromRGB(210, 45, 45), -- Красный для кнопки закрытия
    StrokeColor = Color3.fromRGB(60, 63, 70),

    Font = Enum.Font.SourceSansBold
}
-- # КОНЕЦ НАСТРОЕК #

-- Создание главного окна
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 160)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -80)
mainFrame.BackgroundColor3 = THEME.MainColor
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false -- Скрываем для анимации появления
mainFrame.Parent = screenGui

-- Закругление углов
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Обводка
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = THEME.StrokeColor
stroke.Parent = mainFrame

-- Заголовок (шапка)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = THEME.HeaderColor
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Text = THEME.Title
titleLabel.TextColor3 = THEME.TextColor
titleLabel.BackgroundTransparency = 1
titleLabel.Font = THEME.Font
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Кнопка закрытия
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 1, 0)
closeButton.Position = UDim2.new(1, -35, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = THEME.TextColor
closeButton.BackgroundColor3 = THEME.HeaderColor
closeButton.Font = THEME.Font
closeButton.TextSize = 16
closeButton.Parent = titleBar

-- --- Анимации и логика кнопок ---

-- Функция для создания анимации кнопок
local function setupButtonAnimation(button, hoverColor, originalColor)
    local originalSize = button.Size

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
    end)

    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {Size = originalSize - UDim2.new(0, 4, 0, 4)}):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {Size = originalSize}):Play()
    end)
end

-- Применяем анимацию к кнопке закрытия
setupButtonAnimation(closeButton, THEME.AccentColor, THEME.HeaderColor)

-- Логика закрытия
closeButton.MouseButton1Click:Connect(function()
    mainFrame:Destroy()
end)

-- Основная кнопка "Click Before Steal"
local mainButton = Instance.new("TextButton")
mainButton.Size = UDim2.new(1, -40, 0, 50)
mainButton.Position = UDim2.new(0.5, 0, 0.5, 15)
mainButton.AnchorPoint = Vector2.new(0.5, 0.5)
mainButton.Text = "Click Before Steal"
mainButton.TextColor3 = THEME.TextColor
mainButton.BackgroundColor3 = THEME.ButtonColor
mainButton.Font = THEME.Font
mainButton.TextSize = 20
mainButton.Parent = mainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = mainButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Thickness = 1
buttonStroke.Color = THEME.StrokeColor
buttonStroke.Parent = mainButton

-- Применяем анимацию к основной кнопке
local hoverColor = THEME.ButtonColor:Lerp(Color3.new(1,1,1), 0.1) -- Делаем цвет чуть светлее
setupButtonAnimation(mainButton, hoverColor, THEME.ButtonColor)

-- Логика основной кнопки
local isDebounce = false
mainButton.MouseButton1Click:Connect(function()
    if isDebounce then return end
    isDebounce = true

    local originalText = mainButton.Text
    local spawnLocation = player.RespawnLocation

    -- Таймер обратного отсчета
    mainButton.Text = "Телепортация через: 2"
    task.wait(1)
    mainButton.Text = "Телепортация через: 1"
    task.wait(1)

    -- Телепортация и кик
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        if spawnLocation then
            player.Character.HumanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
        end
    end
    
    player:Kick("Успешно собрано!")
end)

-- Анимация плавного появления GUI
mainFrame.Visible = true
mainFrame.BackgroundTransparency = 1
for _, child in pairs(mainFrame:GetDescendants()) do
    if child:IsA("TextLabel") or child:IsA("TextButton") then
        child.TextTransparency = 1
    end
    if child:IsA("Frame") or child:IsA("TextButton") then
        child.BackgroundTransparency = 1
    end
    if child:IsA("UIStroke") then
        child.Transparency = 1
    end
end

task.wait(0.1) -- Небольшая задержка

local fadeInInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
TweenService:Create(mainFrame, fadeInInfo, {BackgroundTransparency = 0}):Play()
for _, child in pairs(mainFrame:GetDescendants()) do
    if child:IsA("TextLabel") or child:IsA("TextButton") then
        TweenService:Create(child, fadeInInfo, {TextTransparency = 0}):Play()
    end
    if child:IsA("Frame") or child:IsA("TextButton") then
        local originalColor = (child == closeButton) and THEME.HeaderColor or (child.Name == "mainButton" and THEME.ButtonColor or child.BackgroundColor3)
        TweenService:Create(child, fadeInInfo, {BackgroundTransparency = 0}):Play()
    end
     if child:IsA("UIStroke") then
        TweenService:Create(child, fadeInInfo, {Transparency = 0}):Play()
    end
end
