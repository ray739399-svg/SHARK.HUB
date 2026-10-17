

-- SHARK HUB | Interface mobile
-- Interface e scanner demonstrativo de objetos acessíveis.
-- Não garante compatibilidade com mecanismos internos do jogo.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("SHARK_HUB")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SHARK_HUB"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local blue = Color3.fromRGB(0, 170, 255)
local dark = Color3.fromRGB(10, 15, 28)
local white = Color3.fromRGB(240, 248, 255)

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 310, 0, 370)
main.Position = UDim2.new(0.5, -155, 0.5, -185)
main.BackgroundColor3 = dark
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = blue
stroke.Thickness = 2
stroke.Parent = main

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -50, 0, 45)
header.Position = UDim2.new(0, 12, 0, 0)
header.BackgroundTransparency = 1
header.Text = "🦈 SHARK HUB"
header.TextColor3 = blue
header.Font = Enum.Font.GothamBold
header.TextSize = 21
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 35, 0, 35)
close.Position = UDim2.new(1, -42, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(150, 35, 50)
close.Text = "X"
close.TextColor3 = white
close.Font = Enum.Font.GothamBold
close.TextSize = 17
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 9)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Arrastar a janela pelo cabeçalho
local dragging, dragStart, startPos

header.Active = true
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -24, 0, 110)
info.Position = UDim2.new(0, 12, 0, 53)
info.BackgroundColor3 = Color3.fromRGB(17, 27, 45)
info.TextColor3 = white
info.TextSize = 14
info.Font = Enum.Font.Gotham
info.TextWrapped = true
info.TextYAlignment = Enum.TextYAlignment.Top
info.TextXAlignment = Enum.TextXAlignment.Left
info.Text = "SHARK HUB pronto!\nToque em Scanner para procurar ovos acessíveis."
info.Parent = main
Instance.new("UICorner", info).CornerRadius = UDim.new(0, 9)

local function makeButton(text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -24, 0, 39)
    b.Position = UDim2.new(0, 12, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(0, 75, 125)
    b.TextColor3 = white
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)

    local outline = Instance.new("UIStroke")
    outline.Color = blue
    outline.Thickness = 1
    outline.Parent = b

    b.MouseButton1Click:Connect(callback)
    return b
end

makeButton("🔎 ESCANEAR OVOS", 173, function()
    local found = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("ovo") or name:find("egg") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local rarity = obj:GetAttribute("Rarity") or
                    obj:GetAttribute("Raridade") or "Desconhecida"

                local income = obj:GetAttribute("MoneyPerSecond") or
                    obj:GetAttribute("IncomePerSecond") or
                    obj:GetAttribute("Renda") or "Indisponível"

                table.insert(found, {
                    name = obj.Name,
                    rarity = tostring(rarity),
                    income = tostring(income)
                })
            end
        end
    end

    if #found == 0 then
        info.Text = "Nenhum ovo reconhecível encontrado.\nO jogo pode usar nomes ou dados diferentes."
        return
    end

    table.sort(found, function(a, b)
        return tonumber(a.income) ~= nil
            and tonumber(b.income) ~= nil
            and tonumber(a.income) > tonumber(b.income)
    end)

    local best = found[1]
    info.Text = "OVO DETECTADO\nNome: " .. best.name ..
        "\nRaridade: " .. best.rarity ..
        "\nRenda/s: " .. best.income ..
        "\nObjetos encontrados: " .. #found
end)

makeButton("↩ VOLTAR PARA ESTEIRA", 220, function()
    info.Text = "Para voltar automaticamente, é necessário identificar a posição da esteira e os mecanismos permitidos pelo jogo."
end)

makeButton("🪽 VOO", 267, function()
    info.Text = "Voo não ativado: o script não conhece os controles de movimento autorizados deste jogo."
end)

makeButton("🥚 COLETAR OVO", 314, function()
    info.Text = "Coleta não ativada: é necessário usar o mecanismo legítimo de coleta do jogo."
end)

print("SHARK HUB carregado.")
