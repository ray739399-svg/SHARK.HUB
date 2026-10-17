
--[[
    SHARK HUB | Roube um Ovo
    Interface mobile + scanner de dados acessíveis
    LocalScript para Roblox Studio

    Inclui:
    - UI azul neon e preta
    - Painel arrastável por toque
    - Minimizar, fechar e restaurar
    - Seleção de biomas
    - Busca por nome
    - Scanner do maior valor de renda disponível
    - Exibição de nome, raridade, renda, origem e imagem
    - Cancelamento de buscas
    - Botão de retorno à esteira com status informativo

    Observação:
    O scanner só encontra dados expostos ao cliente.
    Teleporte e coleta exigem integração autorizada.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Evita interfaces duplicadas
local oldGui = playerGui:FindFirstChild("SharkHub")
if oldGui then
    oldGui:Destroy()
end

-- Cores
local BLUE = Color3.fromRGB(0, 145, 255)
local CYAN = Color3.fromRGB(0, 220, 255)
local DARK = Color3.fromRGB(6, 10, 20)
local PANEL = Color3.fromRGB(15, 25, 43)
local FIELD = Color3.fromRGB(21, 36, 58)
local WHITE = Color3.fromRGB(240, 247, 255)
local MUTED = Color3.fromRGB(145, 170, 200)
local RED = Color3.fromRGB(175, 48, 60)
local GREEN = Color3.fromRGB(25, 130, 100)

local BIOMES = {
    "Todos os biomas",
    "Cosmic",
    "Flor de Cerejeira",
    "Titan Temple",
    "Anjos e Demônios"
}

local selectedBiome = BIOMES[1]
local searching = false
local scanToken = 0
local minimized = false

-- Interface principal
local gui = Instance.new("ScreenGui")
gui.Name = "SharkHub"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

local function stroke(object, color, thickness)
    local border = Instance.new("UIStroke")
    border.Color = color or BLUE
    border.Thickness = thickness or 1
    border.Parent = object
    return border
end

local function makeLabel(parent, text, size, position, dimensions, color)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Text = text
    item.TextColor3 = color or WHITE
    item.Font = Enum.Font.GothamMedium
    item.TextSize = size
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.Position = position
    item.Size = dimensions
    item.Parent = parent
    return item
end

local function makeButton(parent, text, color, position, dimensions)
    local item = Instance.new("TextButton")
    item.Text = text
    item.TextColor3 = WHITE
    item.Font = Enum.Font.GothamBold
    item.TextSize = 11
    item.BackgroundColor3 = color
    item.Position = position
    item.Size = dimensions
    item.AutoButtonColor = true
    item.Active = true
    item.Parent = parent

    round(item, 8)
    return item
end

local function makeTextBox(parent, placeholder, position, dimensions)
    local item = Instance.new("TextBox")
    item.PlaceholderText = placeholder
    item.PlaceholderColor3 = MUTED
    item.Text = ""
    item.TextColor3 = WHITE
    item.Font = Enum.Font.Gotham
    item.TextSize = 11
    item.ClearTextOnFocus = false
    item.BackgroundColor3 = FIELD
    item.Position = position
    item.Size = dimensions
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = parent

    round(item, 8)
    stroke(item, Color3.fromRGB(35, 75, 110), 1)

    return item
end

-- Botão flutuante
local toggle = makeButton(
    gui, "SHARK HUB", BLUE,
    UDim2.new(0, 12, 0.42, 0),
    UDim2.fromOffset(100, 40)
)
toggle.TextSize = 12
stroke(toggle, CYAN, 1.5)

-- Painel
local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(320, 445)
panel.Position = UDim2.new(0.5, -160, 0.5, -222)
panel.BackgroundColor3 = DARK
panel.ClipsDescendants = true
panel.Active = true
panel.Parent = gui

round(panel, 12)
stroke(panel, BLUE, 1.5)

-- Ajuste de escala para telas pequenas
local uiScale = Instance.new("UIScale")
uiScale.Parent = panel

local function updateScale()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    local viewport = camera.ViewportSize
    local scaleX = (viewport.X - 20) / 320
    local scaleY = (viewport.Y - 30) / 445

    uiScale.Scale = math.clamp(
        math.min(scaleX, scaleY, 1),
        0.65,
        1
    )
end

updateScale()

-- Cabeçalho
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = PANEL
header.Active = true
header.Parent = panel
round(header, 10)

local title = makeLabel(
    header, "SHARK HUB", 15,
    UDim2.new(0, 12, 0, 0),
    UDim2.new(1, -100, 1, 0), CYAN
)
title.Font = Enum.Font.GothamBold

local minimizeButton = makeButton(
    header, "—", DARK,
    UDim2.new(1, -62, 0, 8),
    UDim2.fromOffset(24, 26)
)

local closeButton = makeButton(
    header, "X", RED,
    UDim2.new(1, -32, 0, 8),
    UDim2.fromOffset(24, 26)
)

-- Conteúdo rolável
local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Position = UDim2.new(0, 0, 0, 44)
content.Size = UDim2.new(1, 0, 1, -46)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = CYAN
content.CanvasSize = UDim2.new(0, 0, 0, 470)
content.Active = true
content.Parent = panel

-- Título do scanner
makeLabel(
    content, "SCANNER DE OVOS", 11,
    UDim2.new(0, 12, 0, 3),
    UDim2.new(1, -24, 0, 20), MUTED
)

-- Seleção de bioma
local biomeButton = makeButton(
    content, "BIOMA: Todos os biomas  v", BLUE,
    UDim2.new(0, 10, 0, 27),
    UDim2.new(1, -20, 0, 32)
)
biomeButton.TextSize = 10

local biomeIndex = 1

biomeButton.Activated:Connect(function()
    biomeIndex += 1

    if biomeIndex > #BIOMES then
        biomeIndex = 1
    end

    selectedBiome = BIOMES[biomeIndex]
    biomeButton.Text = "BIOMA: " .. selectedBiome .. "  v"
end)

-- Pesquisa por nome
local searchBox = makeTextBox(
    content, "Pesquisar ovo ou pet...",
    UDim2.new(0, 10, 0, 66),
    UDim2.new(1, -20, 0, 31)
)
searchBox.ClearTextOnFocus = false

-- Cartão de resultado
local card = Instance.new("Frame")
card.Name = "ResultCard"
card.Position = UDim2.new(0, 10, 0, 105)
card.Size = UDim2.new(1, -20, 0, 126)
card.BackgroundColor3 = PANEL
card.Parent = content
round(card, 10)
stroke(card, Color3.fromRGB(28, 65, 100), 1)

local imageFrame = Instance.new("Frame")
imageFrame.Position = UDim2.new(0, 8, 0, 10)
imageFrame.Size = UDim2.fromOffset(86, 104)
imageFrame.BackgroundColor3 = FIELD
imageFrame.Parent = card
round(imageFrame, 8)

local petImage = Instance.new("ImageLabel")
petImage.Name = "PetImage"
petImage.BackgroundTransparency = 1
petImage.Size = UDim2.new(1, -6, 1, -6)
petImage.Position = UDim2.new(0, 3, 0, 3)
petImage.ScaleType = Enum.ScaleType.Fit
petImage.Parent = imageFrame
round(petImage, 6)

local placeholder = makeLabel(
    imageFrame, "SEM IMAGEM", 9,
    UDim2.new(0, 2, 0, 0),
    UDim2.new(1, -4, 1, 0), MUTED
)
placeholder.TextXAlignment = Enum.TextXAlignment.Center

local petName = makeLabel(
    card, "Aguardando busca...", 11,
    UDim2.new(0, 102, 0, 7),
    UDim2.new(1, -110, 0, 30), WHITE
)

local rarityLabel = makeLabel(
    card, "Raridade: --", 10,
    UDim2.new(0, 102, 0, 38),
    UDim2.new(1, -110, 0, 20), CYAN
)

local incomeLabel = makeLabel(
    card, "Renda/s: --", 10,
    UDim2.new(0, 102, 0, 60),
    UDim2.new(1, -110, 0, 20), WHITE
)

local originLabel = makeLabel(
    card, "Origem: --", 9,
    UDim2.new(0, 102, 0, 82),
    UDim2.new(1, -110, 0, 28), MUTED
)

-- Status
local status = makeLabel(
    content, "Status: pronto",
    10, UDim2.new(0, 12, 0, 235),
    UDim2.new(1, -24, 0, 32), MUTED
)

-- Botões de busca e parada
local scanButton = makeButton(
    content, "BUSCAR MELHOR OVO", BLUE,
    UDim2.new(0, 10, 0, 271),
    UDim2.new(1, -20, 0, 34)
)

local stopButton = makeButton(
    content, "PARAR BUSCA", Color3.fromRGB(45, 57, 77),
    UDim2.new(0, 10, 0, 312),
    UDim2.new(0.5, -15, 0, 32)
)

local backButton = makeButton(
    content, "VOLTAR À ESTEIRA", Color3.fromRGB(20, 65, 100),
    UDim2.new(0.5, 5, 0, 312),
    UDim2.new(0.5, -15, 0, 32)
)

-- Informações adicionais
local info = makeLabel(
    content,
    "Os resultados dependem dos dados acessíveis ao cliente.",
    9,
    UDim2.new(0, 12, 0, 353),
    UDim2.new(1, -24, 0, 36),
    MUTED
)

local footer = makeLabel(
    content, "SHARK HUB  •  MOBILE",
    9, UDim2.new(0, 12, 0, 401),
    UDim2.new(1, -24, 0, 20), CYAN
)

-- Scanner: lê apenas dados acessíveis
local function getNumber(object, attributeName, childName)
    local attribute = object:GetAttribute(attributeName)

    if attribute ~= nil then
        local value = tonumber(attribute)
        if value then
            return value
        end
    end

    local child = object:FindFirstChild(childName)

    if child and (
        child:IsA("NumberValue")
        or child:IsA("IntValue")
    ) then
        return child.Value
    end

    return nil
end

local function getBiome(object)
    local biome = object:GetAttribute("Biome")

    if biome then
        return tostring(biome)
    end

    local current = object

    while current and current ~= Workspace do
        local name = string.lower(current.Name)

        if string.find(name, "cosmic") then
            return "Cosmic"
        elseif string.find(name, "cerejeira")
            or string.find(name, "cherry") then
            return "Flor de Cerejeira"
        elseif string.find(name, "titan") then
            return "Titan Temple"
        elseif string.find(name, "demon")
            or string.find(name, "angel")
            or string.find(name, "anjo") then
            return "Anjos e Demônios"
        end

        current = current.Parent
    end

    return nil
end

local function matchesBiome(object)
    if selectedBiome == "Todos os biomas" then
        return true
    end

    local actualBiome = getBiome(object)

    if not actualBiome then
        return false
    end

    return string.lower(actualBiome)
        == string.lower(selectedBiome)
end

local function getImageId(object)
    local image = object:GetAttribute("ImageId")
        or object:GetAttribute("PetImage")

    if image then
        local value = tostring(image)

        if string.match(value, "^%d+$") then
            return "rbxassetid://" .. value
        end

        if string.match(value, "^rbxassetid://%d+$") then
            return value
        end
    end

    return nil
end

local function scanBest(token)
    local best = nil
    local count = 0
    local processed = 0

    local query = string.lower(searchBox.Text)

    local descendants = Workspace:GetDescendants()

    for _, object in ipairs(descendants) do
        if token ~= scanToken then
            return nil, count, true
        end

        processed += 1

        if processed % 150 == 0 then
            status.Text = "Status: analisando " .. processed .. " objetos..."
            task.wait()
        end

        if object:IsA("Model") or object:IsA("BasePart") then
            local lowerName = string.lower(object.Name)

            local petAttribute = object:GetAttribute("PetName")
            local looksLikeEgg =
                string.find(lowerName, "egg")
                or string.find(lowerName, "ovo")
                or petAttribute ~= nil

            local matchesSearch =
                query == ""
                or string.find(lowerName, query, 1, true)
                or (
                    petAttribute
                    and string.find(
                        string.lower(tostring(petAttribute)),
                        query,
                        1,
                        true
                    )
                )

            if looksLikeEgg
                and matchesSearch
                and matchesBiome(object) then

                local money = getNumber(
                    object,
                    "MoneyPerSecond",
                    "MoneyPerSecond"
                )

                if money then
                    count += 1

                    if not best or money > best.income then
                        best = {
                            object = object,
                            name = tostring(
                                petAttribute or object.Name
                            ),
                            rarity = tostring(
                                object:GetAttribute("Rarity") or "--"
                            ),
                            egg = object:GetAttribute("EggName")
                                or object.Name,
                            biome = getBiome(object) or "--",
                            income = money,
                            image = getImageId(object)
                        }
                    end
                end
            end
        end
    end

    return best, count, false
end

local function showNoResult(message)
    petName.Text = "Nenhum resultado"
    rarityLabel.Text = "Raridade: --"
    incomeLabel.Text = "Renda/s: --"
    originLabel.Text = "Origem: --"
    petImage.Image = ""
    placeholder.Visible = true
    status.Text = message
end

scanButton.Activated:Connect(function()
    if searching then
        status.Text = "Status: a busca já está em andamento"
        return
    end

    searching = true
    scanToken += 1

    local myToken = scanToken

    scanButton.Text = "BUSCANDO..."
    status.Text = "Status: iniciando scanner..."

    task.spawn(function()
        local ok, best, count, cancelled = pcall(function()
            local result, total, wasCancelled = scanBest(myToken)
            return result, total, wasCancelled
        end)

        if myToken ~= scanToken then
            return
        end

        searching = false
        scanButton.Text = "BUSCAR MELHOR OVO"

        if not ok then
            showNoResult("Erro ao ler os dados acessíveis")
            return
        end

        if cancelled then
            status.Text = "Status: busca cancelada"
            return
        end

        if not best then
            showNoResult(
                "Nenhum resultado com renda disponível para esse filtro"
            )
            return
        end

        petName.Text = best.name
        rarityLabel.Text = "Raridade: " .. best.rarity
        incomeLabel.Text = "Renda/s: " .. tostring(best.income)
        originLabel.Text = "Origem: " .. tostring(best.egg)

        if best.image then
            petImage.Image = best.image
            placeholder.Visible = false
        else
            petImage.Image = ""
            placeholder.Visible = true
        end

        status.Text = "Status: melhor renda entre "
            .. tostring(count) .. " resultados"

        info.Text = "Bioma detectado: " .. best.biome
    end)
end)

-- Cancelar busca em andamento
stopButton.Activated:Connect(function()
    scanToken += 1
    searching = false
    scanButton.Text = "BUSCAR MELHOR OVO"
    status.Text = "Status: busca cancelada"
end)

-- Não inventa teleporte ou interação do jogo
backButton.Activated:Connect(function()
    status.Text = "Use a interação oficial do jogo para voltar à esteira"
end)

-- Minimizar e restaurar
minimizeButton.Activated:Connect(function()
    minimized = not minimized

    content.Visible = not minimized

    panel.Size = minimized
        and UDim2.fromOffset(320, 42)
        or UDim2.fromOffset(320, 445)

    minimizeButton.Text = minimized and "+" or "—"

    updateScale()
end)

-- Fechar e reabrir
closeButton.Activated:Connect(function()
    panel.Visible = false
    toggle.Visible = true
end)

toggle.Activated:Connect(function()
    panel.Visible = true
    toggle.Visible = false
    updateScale()
end)

-- Arrastar por toque ou mouse
local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = panel.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        panel.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

-- Atualizar escala se a tela mudar
local function connectCamera()
    local camera = Workspace.CurrentCamera

    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(
            updateScale
        )
    end
end

connectCamera()

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(
    connectCamera
)

toggle.Visible = false
panel.Visible = true

status.Text = "Status: pronto para buscar"

print("[SHARK HUB] Interface carregada.")
