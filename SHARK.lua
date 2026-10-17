
--[[
    SHARK HUB | Mobile UI
    Roblox Lua - interface e scanner visual
    A coleta real exige integração autorizada com o jogo.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Evitar duplicar a interface
local old = playerGui:FindFirstChild("SharkHub")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SharkHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local blue = Color3.fromRGB(0, 170, 255)
local dark = Color3.fromRGB(10, 15, 25)
local panelColor = Color3.fromRGB(15, 23, 38)
local white = Color3.fromRGB(240, 248, 255)
local muted = Color3.fromRGB(155, 180, 205)

local function create(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(225, 245),
    Position = UDim2.new(1, -238, 0.35, 0),
    BackgroundColor3 = dark,
    BorderSizePixel = 0,
    Active = true
}, gui)

create("UICorner", {CornerRadius = UDim.new(0, 12)}, main)
create("UIStroke", {
    Color = blue,
    Thickness = 1.5,
    Transparency = 0.15
}, main)

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = panelColor,
    BorderSizePixel = 0
}, main)
create("UICorner", {CornerRadius = UDim.new(0, 12)}, header)

create("TextLabel", {
    Size = UDim2.new(1, -76, 1, 0),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Text = "SHARK HUB",
    TextColor3 = blue,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local minimize = create("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -65, 0, 7),
    BackgroundColor3 = Color3.fromRGB(30, 50, 70),
    Text = "—",
    TextColor3 = white,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0
}, header)
create("UICorner", {CornerRadius = UDim.new(0, 7)}, minimize)

local close = create("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -32, 0, 7),
    BackgroundColor3 = Color3.fromRGB(120, 35, 50),
    Text = "×",
    TextColor3 = white,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0
}, header)
create("UICorner", {CornerRadius = UDim.new(0, 7)}, close)

local content = create("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -20, 1, -55),
    Position = UDim2.fromOffset(10, 49),
    BackgroundTransparency = 1
}, main)

create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 23),
    BackgroundTransparency = 1,
    Text = "EGG SCANNER  /  MOBILE",
    TextColor3 = muted,
    TextSize = 10,
    Font = Enum.Font.GothamBold
}, content)

local status = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 29),
    Position = UDim2.fromOffset(0, 24),
    BackgroundColor3 = Color3.fromRGB(20, 35, 50),
    Text = "STATUS: AGUARDANDO",
    TextColor3 = white,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0
}, content)
create("UICorner", {CornerRadius = UDim.new(0, 7)}, status)

local result = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.fromOffset(0, 57),
    BackgroundTransparency = 1,
    Text = "Melhor ovo: não verificado",
    TextColor3 = muted,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextWrapped = true
}, content)

local function makeButton(text, y, color)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        Position = UDim2.fromOffset(0, y),
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = white,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = true
    }, content)

    create("UICorner", {CornerRadius = UDim.new(0, 8)}, button)
    return button
end

local scanButton = makeButton(
    "⌕  SCAN MELHOR OVO", 88, Color3.fromRGB(0, 100, 175)
)
local collectButton = makeButton(
    "▶  PEGAR OVO", 129, Color3.fromRGB(0, 135, 100)
)
local stopButton = makeButton(
    "■  PARAR DE PEGAR", 170, Color3.fromRGB(125, 40, 55)
)

local running = false
local minimized = false
local previousHeight = main.Size

-- Scanner visual: procura objetos com nomes relacionados a ovos.
local function scanEggs()
    local candidates = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = string.lower(obj.Name)

            if string.find(name, "egg")
                or string.find(name, "ovo") then

                local position

                if obj:IsA("Model") then
                    position = obj:GetPivot().Position
                else
                    position = obj.Position
                end

                local character = player.Character
                local root = character
                    and character:FindFirstChild("HumanoidRootPart")

                local distance = root
                    and (position - root.Position).Magnitude
                    or math.huge

                table.insert(candidates, {
                    name = obj.Name,
                    distance = distance
                })
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.distance < b.distance
    end)

    if #candidates == 0 then
        result.Text = "Nenhum objeto com nome de ovo encontrado."
        status.Text = "STATUS: SCAN CONCLUÍDO"
        return
    end

    local best = candidates[1]
    local distanceText = best.distance == math.huge
        and "distância indisponível"
        or string.format("%.0f studs", best.distance)

    result.Text = "Objeto: " .. best.name .. " (" .. distanceText .. ")"
    status.Text = "STATUS: " .. #candidates .. " OBJETO(S)"
end

scanButton.Activated:Connect(function()
    status.Text = "STATUS: ANALISANDO..."
    result.Text = "Procurando objetos visíveis..."
    task.spawn(scanEggs)
end)

collectButton.Activated:Connect(function()
    running = true
    status.Text = "STATUS: COLETA NÃO INTEGRADA"
    result.Text = "Conecte uma função autorizada de coleta."
end)

stopButton.Activated:Connect(function()
    running = false
    status.Text = "STATUS: PARADO"
    result.Text = "Nenhuma ação automática está em execução."
end)

minimize.Activated:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    main.Size = minimized
        and UDim2.fromOffset(225, 42)
        or previousHeight

    minimize.Text = minimized and "+" or "—"
end)

close.Activated:Connect(function()
    running = false
    gui:Destroy()
end)

-- Arrastar o painel pelo cabeçalho, inclusive em telas touch.
local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)
