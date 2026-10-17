
-- SHARK HUB | Mobile Edition
-- Interface compacta para Roblox Studio
-- Scanner de ovos com dados acessíveis ao cliente

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("SharkHub")
if previous then
    previous:Destroy()
end

-- CORES
local BLUE = Color3.fromRGB(0, 145, 255)
local CYAN = Color3.fromRGB(0, 220, 255)
local DARK = Color3.fromRGB(7, 11, 20)
local PANEL = Color3.fromRGB(15, 25, 42)
local WHITE = Color3.fromRGB(245, 249, 255)
local MUTED = Color3.fromRGB(145, 165, 190)
local GREEN = Color3.fromRGB(20, 130, 95)
local RED = Color3.fromRGB(160, 45, 55)

local scanning = false
local collecting = false
local scanId = 0
local bestResult = nil

-- FUNÇÕES DE UI
local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
end

local function border(object, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Parent = object
end

local function makeLabel(parent, text, size, position, dimensions, color)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or WHITE
    label.Font = Enum.Font.GothamBold
    label.TextSize = size
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = position
    label.Size = dimensions
    label.Parent = parent
    return label
end

local function makeButton(parent, text, color, position, dimensions)
    local button = Instance.new("TextButton")
    button.Text = text
    button.TextColor3 = WHITE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.BackgroundColor3 = color
    button.Position = position
    button.Size = dimensions
    button.AutoButtonColor = true
    button.Parent = parent

    corner(button, 8)
    return button
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SharkHub"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

-- BOTÃO FLUTUANTE
local toggle = makeButton(
    gui,
    "SHARK",
    BLUE,
    UDim2.new(0, 12, 0.4, 0),
    UDim2.fromOffset(76, 38)
)
border(toggle, CYAN, 1.5)

-- PAINEL PRINCIPAL
local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(290, 275)
panel.Position = UDim2.new(0.5, -145, 0.5, -137)
panel.BackgroundColor3 = DARK
panel.ClipsDescendants = true
panel.Parent = gui

corner(panel, 12)
border(panel, BLUE, 1.5)

-- CABEÇALHO
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = PANEL
header.Active = true
header.Parent = panel
corner(header, 10)

local title = makeLabel(
    header,
    "SHARK HUB",
    15,
    UDim2.new(0, 12, 0, 0),
    UDim2.new(1, -95, 1, 0),
    CYAN
)

local minimize = makeButton(
    header, "—", DARK,
    UDim2.new(1, -61, 0, 7),
    UDim2.fromOffset(24, 26)
)

local close = makeButton(
    header, "X", RED,
    UDim2.new(1, -31, 0, 7),
    UDim2.fromOffset(24, 26)
)

-- RESULTADO DO SCANNER
makeLabel(
    panel,
    "MELHOR OVO ENCONTRADO",
    10,
    UDim2.new(0, 12, 0, 48),
    UDim2.new(1, -24, 0, 18),
    MUTED
)

local resultName = makeLabel(
    panel,
    "Nenhum ovo selecionado",
    12,
    UDim2.new(0, 12, 0, 70),
    UDim2.new(1, -24, 0, 28),
    WHITE
)

local resultRarity = makeLabel(
    panel,
    "Raridade: --",
    10,
    UDim2.new(0, 12, 0, 99),
    UDim2.new(1, -24, 0, 18),
    CYAN
)

local resultIncome = makeLabel(
    panel,
    "Renda/s: --",
    10,
    UDim2.new(0, 12, 0, 119),
    UDim2.new(1, -24, 0, 18),
    WHITE
)

local status = makeLabel(
    panel,
    "Status: pronto",
    10,
    UDim2.new(0, 12, 0, 143),
    UDim2.new(1, -24, 0, 25),
    MUTED
)

-- BOTÕES PRINCIPAIS
local scanButton = makeButton(
    panel,
    "SCAN MELHOR OVO",
    BLUE,
    UDim2.new(0, 10, 0, 174),
    UDim2.new(1, -20, 0, 30)
)

local collectButton = makeButton(
    panel,
    "PEGAR OVO",
    GREEN,
    UDim2.new(0, 10, 0, 211),
    UDim2.new(0.5, -15, 0, 32)
)

local stopButton = makeButton(
    panel,
    "PARAR DE PEGAR",
    RED,
    UDim2.new(0.5, 5, 0, 211),
    UDim2.new(0.5, -15, 0, 32)
)

-- SCANNER
local function scanBest(token)
    local best = nil
    local count = 0

    for _, object in ipairs(Workspace:GetDescendants()) do
        if token ~= scanId then
            return nil, count, true
        end

        if object:IsA("Model") or object:IsA("BasePart") then
            local name = string.lower(object.Name)

            local isEgg =
                string.find(name, "egg", 1, true)
                or string.find(name, "ovo", 1, true)

            if isEgg then
                local income = tonumber(
                    object:GetAttribute("MoneyPerSecond")
                )

                if income then
                    count += 1

                    if not best or income > best.income then
                        best = {
                            object = object,
                            name = tostring(
                                object:GetAttribute("PetName")
                                or object.Name
                            ),
                            rarity = tostring(
                                object:GetAttribute("Rarity")
                                or "--"
                            ),
                            income = income
                        }
                    end
                end
            end
        end
    end

    return best, count, false
end

scanButton.Activated:Connect(function()
    if scanning then
        status.Text = "Status: scanner já está ativo"
        return
    end

    scanning = true
    scanId += 1
    local myId = scanId

    scanButton.Text = "ESCANEANDO..."
    status.Text = "Status: procurando ovos..."

    task.spawn(function()
        local ok, result, count, cancelled = pcall(function()
            return scanBest(myId)
        end)

        if myId ~= scanId then
            return
        end

        scanning = false
        scanButton.Text = "SCAN MELHOR OVO"

        if not ok then
            status.Text = "Erro ao consultar dados acessíveis"
            return
        end

        if cancelled then
            status.Text = "Busca cancelada"
            return
        end

        if not result then
            bestResult = nil
            resultName.Text = "Nenhum resultado disponível"
            resultRarity.Text = "Raridade: --"
            resultIncome.Text = "Renda/s: --"
            status.Text = "Objetos encontrados com renda: " .. count
            return
        end

        bestResult = result
        resultName.Text = result.name
        resultRarity.Text = "Raridade: " .. result.rarity
        resultIncome.Text = "Renda/s: " .. tostring(result.income)
        status.Text = "Melhor resultado entre " .. count .. " ovos"
    end)
end)

-- PEGAR OVO
-- Este botão não executa coleta no jogo.
-- A ação real requer integração autorizada do criador.
collectButton.Activated:Connect(function()
    if not bestResult then
        status.Text = "Faça o scanner primeiro"
        return
    end

    status.Text = "Ovo selecionado: " .. bestResult.name
        .. " | Coleta oficial não configurada"
end)

-- PARAR
stopButton.Activated:Connect(function()
    scanId += 1
    scanning = false
    collecting = false
    scanButton.Text = "SCAN MELHOR OVO"
    status.Text = "Status: ações locais interrompidas"
end)

-- MINIMIZAR / RESTAURAR
local minimized = false

minimize.Activated:Connect(function()
    minimized = not minimized

    for _, object in ipairs({
        resultName,
        resultRarity,
        resultIncome,
        status,
        scanButton,
        collectButton,
        stopButton
    }) do
        object.Visible = not minimized
    end

    panel.Size = minimized
        and UDim2.fromOffset(290, 40)
        or UDim2.fromOffset(290, 275)

    minimize.Text = minimized and "+" or "—"
end)

-- FECHAR / REABRIR
close.Activated:Connect(function()
    panel.Visible = false
    toggle.Visible = true
end)

toggle.Activated:Connect(function()
    panel.Visible = true
    toggle.Visible = false
end)

-- ARRASTAR NO CELULAR OU PC
local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

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
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
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

toggle.Visible = false
panel.Visible = true

print("[SHARK HUB] Menu carregado.")
"
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
