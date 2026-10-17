-- SHARK HUB - Interface Premium Mobile-First
-- Identidade visual: Tubarão + Tecnologia (Preto, Azul-Escuro, Azul Neon)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- PALETA DE CORES
-- ============================================================
local CORES = {
    FundoPrincipal = Color3.fromRGB(8, 12, 20),      -- Preto azulado profundo
    FundoSecundario = Color3.fromRGB(12, 20, 35),    -- Azul-escuro
    FundoBotao = Color3.fromRGB(18, 30, 50),         -- Azul escuro para botões
    AzulNeon = Color3.fromRGB(0, 180, 255),          -- Azul neon principal
    AzulNeonEscuro = Color3.fromRGB(0, 100, 180),    -- Azul neon para hover
    TextoPrincipal = Color3.fromRGB(240, 245, 255),  -- Branco levemente azulado
    TextoSecundario = Color3.fromRGB(150, 170, 200), -- Cinza azulado
    Perigo = Color3.fromRGB(255, 60, 80),            -- Vermelho para fechar
}

-- ============================================================
-- CONTAINER PRINCIPAL
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SHARK_HUB"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============================================================
-- PAINEL PRINCIPAL
-- ============================================================
local painel = Instance.new("Frame")
painel.Name = "PainelPrincipal"
painel.Size = UDim2.new(0, 240, 0, 320)
painel.Position = UDim2.new(1, -260, 0.5, -160) -- Lado direito da tela
painel.BackgroundColor3 = CORES.FundoPrincipal
painel.BorderSizePixel = 0
painel.Active = true
painel.Draggable = false -- Vamos implementar arrasto customizado para mobile
painel.Parent = screenGui

-- Canto arredondado do painel
local cantoPainel = Instance.new("UICorner")
cantoPainel.CornerRadius = UDim.new(0, 12)
cantoPainel.Parent = painel

-- Contorno luminoso (UIStroke)
local contornoPainel = Instance.new("UIStroke")
contornoPainel.Thickness = 1.5
contornoPainel.Color = CORES.AzulNeon
contornoPainel.Transparency = 0.3
contornoPainel.Parent = painel

-- ============================================================
-- CABEÇALHO (Título + Botões de Controle)
-- ============================================================
local cabecalho = Instance.new("Frame")
cabecalho.Name = "Cabecalho"
cabecalho.Size = UDim2.new(1, 0, 0, 40)
cabecalho.BackgroundColor3 = CORES.FundoSecundario
cabecalho.BorderSizePixel = 0
cabecalho.Parent = painel

local cantoCabecalho = Instance.new("UICorner")
cantoCabecalho.CornerRadius = UDim.new(0, 12)
cantoCabecalho.Parent = cabecalho

-- Máscara para o cabeçalho não vazar o canto de baixo
local mascaraCabecalho = Instance.new("Frame")
mascaraCabecalho.Size = UDim2.new(1, 0, 0.5, 0)
mascaraCabecalho.Position = UDim2.new(0, 0, 0.5, 0)
mascaraCabecalho.BackgroundColor3 = CORES.FundoSecundario
mascaraCabecalho.BorderSizePixel = 0
mascaraCabecalho.Parent = cabecalho

-- Título SHARK HUB
local titulo = Instance.new("TextLabel")
titulo.Name = "Titulo"
titulo.Size = UDim2.new(1, -80, 1, 0)
titulo.Position = UDim2.new(0, 10, 0, 0)
titulo.BackgroundTransparency = 1
titulo.Text = "SHARK HUB"
titulo.TextColor3 = CORES.AzulNeon
titulo.TextSize = 16
titulo.Font = Enum.Font.GothamBold
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Parent = cabecalho

-- Símbolo de tubarão (texto simples, substitua por imagem se quiser)
local simboloTubarao = Instance.new("TextLabel")
simboloTubarao.Name = "Simbolo"
simboloTubarao.Size = UDim2.new(0, 24, 0, 24)
simboloTubarao.Position = UDim2.new(0, -28, 0.5, -12)
simboloTubarao.BackgroundTransparency = 1
simboloTubarao.Text = "🦈"
simboloTubarao.TextColor3 = CORES.AzulNeon
simboloTubarao.TextSize = 16
simboloTubarao.Parent = titulo

-- Botão Minimizar
local btnMinimizar = Instance.new("TextButton")
btnMinimizar.Name = "BtnMinimizar"
btnMinimizar.Size = UDim2.new(0, 28, 0, 28)
btnMinimizar.Position = UDim2.new(1, -66, 0.5, -14)
btnMinimizar.BackgroundColor3 = CORES.FundoBotao
btnMinimizar.BorderSizePixel = 0
btnMinimizar.Text = "−"
btnMinimizar.TextColor3 = CORES.TextoPrincipal
btnMinimizar.TextSize = 18
btnMinimizar.Font = Enum.Font.GothamBold
btnMinimizar.Parent = cabecalho

local cantoMin = Instance.new("UICorner")
cantoMin.CornerRadius = UDim.new(0, 6)
cantoMin.Parent = btnMinimizar

-- Botão Fechar
local btnFechar = Instance.new("TextButton")
btnFechar.Name = "BtnFechar"
btnFechar.Size = UDim2.new(0, 28, 0, 28)
btnFechar.Position = UDim2.new(1, -34, 0.5, -14)
btnFechar.BackgroundColor3 = CORES.FundoBotao
btnFechar.BorderSizePixel = 0
btnFechar.Text = "✕"
btnFechar.TextColor3 = CORES.Perigo
btnFechar.TextSize = 14
btnFechar.Font = Enum.Font.GothamBold
btnFechar.Parent = cabecalho

local cantoFechar = Instance.new("UICorner")
cantoFechar.CornerRadius = UDim.new(0, 6)
cantoFechar.Parent = btnFechar

-- ============================================================
-- ÁREA DE CONTEÚDO (Botões de Função)
-- ============================================================
local conteudo = Instance.new("Frame")
conteudo.Name = "Conteudo"
conteudo.Size = UDim2.new(1, -16, 1, -56)
conteudo.Position = UDim2.new(0, 8, 0, 48)
conteudo.BackgroundTransparency = 1
conteudo.Parent = painel

local layoutConteudo = Instance.new("UIListLayout")
layoutConteudo.Padding = UDim.new(0, 8)
layoutConteudo.SortOrder = Enum.SortOrder.LayoutOrder
layoutConteudo.Parent = conteudo

-- Função auxiliar para criar botões de função
local function criarBotaoFuncao(nome, textoBotao, callback)
    local botao = Instance.new("TextButton")
    botao.Name = nome
    botao.Size = UDim2.new(1, 0, 0, 40)
    botao.BackgroundColor3 = CORES.FundoBotao
    botao.BorderSizePixel = 0
    botao.Text = textoBotao
    botao.TextColor3 = CORES.TextoPrincipal
    botao.TextSize = 13
    botao.Font = Enum.Font.GothamMedium
    botao.Parent = conteudo

    local cantoBotao = Instance.new("UICorner")
    cantoBotao.CornerRadius = UDim.new(0, 8)
    cantoBotao.Parent = botao

    local contornoBotao = Instance.new("UIStroke")
    contornoBotao.Thickness = 1
    contornoBotao.Color = CORES.AzulNeonEscuro
    contornoBotao.Transparency = 0.7
    contornoBotao.Parent = botao

    -- Efeitos de hover (PC)
    botao.MouseEnter:Connect(function()
        TweenService:Create(botao, TweenInfo.new(0.15), {
            BackgroundColor3 = CORES.AzulNeonEscuro,
            TextColor3 = CORES.AzulNeon
        }):Play()
        TweenService:Create(contornoBotao, TweenInfo.new(0.15), {
            Transparency = 0.2
        }):Play()
    end)

    botao.MouseLeave:Connect(function()
        TweenService:Create(botao, TweenInfo.new(0.15), {
            BackgroundColor3 = CORES.FundoBotao,
            TextColor3 = CORES.TextoPrincipal
        }):Play()
        TweenService:Create(contornoBotao, TweenInfo.new(0.15), {
            Transparency = 0.7
        }):Play()
    end)

    -- Efeito de toque (Mobile)
    botao.MouseButton1Click:Connect(function()
        -- Animação de clique
        local tamanhoOriginal = botao.Size
        TweenService:Create(botao, TweenInfo.new(0.08), {
            Size = UDim2.new(1, -4, 0, 36)
        }):Play()
        task.wait(0.08)
        TweenService:Create(botao, TweenInfo.new(0.08), {
            Size = tamanhoOriginal
        }):Play()

        if callback then
            local sucesso, erro = pcall(callback)
            if not sucesso then
                warn("[SHARK HUB] Erro no botão '" .. textoBotao .. "': " .. tostring(erro))
            end
        end
    end)

    return botao
end

-- ============================================================
-- BOTÕES DE FUNÇÃO (Placeholders - Preencha com funções reais)
-- ============================================================
-- IMPORTANTE: Estes botões são apenas exemplos estruturais.
-- Substitua os callbacks pelas funções reais que você encontrar
-- em documentação autorizada ou código-fonte permitido.

criarBotaoFuncao("BtnExemplo1", "Função 1 (Placeholder)", function()
    print("[SHARK HUB] Botão 1 clicado - Substitua pela função real.")
end)

criarBotaoFuncao("BtnExemplo2", "Função 2 (Placeholder)", function()
    print("[SHARK HUB] Botão 2 clicado - Substitua pela função real.")
end)

criarBotaoFuncao("BtnExemplo3", "Função 3 (Placeholder)", function()
    print("[SHARK HUB] Botão 3 clicado - Substitua pela função real.")
end)

criarBotaoFuncao("BtnConfig", "Configurações", function()
    print("[SHARK HUB] Abrir configurações - Implemente aqui.")
end)

-- ============================================================
-- BOTÃO RESTAURAR (aparece quando minimizado)
-- ============================================================
local btnRestaurar = Instance.new("TextButton")
btnRestaurar.Name = "BtnRestaurar"
btnRestaurar.Size = UDim2.new(0, 44, 0, 44)
btnRestaurar.Position = UDim2.new(1, -60, 0.5, -22)
btnRestaurar.BackgroundColor3 = CORES.FundoPrincipal
btnRestaurar.BorderSizePixel = 0
btnRestaurar.Text = "🦈"
btnRestaurar.TextColor3 = CORES.AzulNeon
btnRestaurar.TextSize = 22
btnRestaurar.Font = Enum.Font.GothamBold
btnRestaurar.Visible = false
btnRestaurar.Parent = screenGui

local cantoRestaurar = Instance.new("UICorner")
cantoRestaurar.CornerRadius = UDim.new(0, 22)
cantoRestaurar.Parent = btnRestaurar

local contornoRestaurar = Instance.new("UIStroke")
contornoRestaurar.Thickness = 2
contornoRestaurar.Color = CORES.AzulNeon
contornoRestaurar.Transparency = 0.2
contornoRestaurar.Parent = btnRestaurar

-- ============================================================
-- LÓGICA DE ARRASTAR (Mobile + PC)
-- ============================================================
local arrastando = false
local posicaoInicialInput
local posicaoInicialPainel

local function iniciarArrasto(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        arrastando = true
        posicaoInicialInput = input.Position
        posicaoInicialPainel = painel.Position
    end
end

local function atualizarArrasto(input)
    if not arrastando then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - posicaoInicialInput
        painel.Position = UDim2.new(
            posicaoInicialPainel.X.Scale,
            posicaoInicialPainel.X.Offset + delta.X,
            posicaoInicialPainel.Y.Scale,
            posicaoInicialPainel.Y.Offset + delta.Y
        )
    end
end

local function finalizarArrasto(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        arrastando = false
    end
end

cabecalho.InputBegan:Connect(iniciarArrasto)
UserInputService.InputChanged:Connect(atualizarArrasto)
UserInputService.InputEnded:Connect(finalizarArrasto)

-- ============================================================
-- LÓGICA DE MINIMIZAR / RESTAURAR / FECHAR
-- ============================================================
local minimizado = false
local animacaoAtiva = false

local function animarTamanho(objeto, tamanhoAlvo, tempo)
    if animacaoAtiva then return end
    animacaoAtiva = true
    local tween = TweenService:Create(objeto, TweenInfo.new(tempo, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = tamanhoAlvo
    })
    tween:Play()
    tween.Completed:Connect(function()
        animacaoAtiva = false
    end)
end

btnMinimizar.MouseButton1Click:Connect(function()
    if minimizado then return end
    minimizado = true
    conteudo.Visible = false
    animarTamanho(painel, UDim2.new(0, 240, 0, 40), 0.25)
    task.wait(0.25)
    painel.Visible = false
    btnRestaurar.Visible = true
end)

btnRestaurar.MouseButton1Click:Connect(function()
    if not minimizado then return end
    minimizado = false
    btnRestaurar.Visible = false
    painel.Visible = true
    painel.Size = UDim2.new(0, 240, 0, 40)
    animarTamanho(painel, UDim2.new(0, 240, 0, 320), 0.25)
    task.wait(0.25)
    conteudo.Visible = true
end)

btnFechar.MouseButton1Click:Connect(function()
    -- Animação de fechamento
    local tween = TweenService:Create(painel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function()
        painel:Destroy()
        btnRestaurar:Destroy()
    end)
end)

-- ============================================================
-- EFEITOS DE HOVER NOS BOTÕES DE CONTROLE
-- ============================================================
local function adicionarHoverBotaoControle(botao, corHover)
    botao.MouseEnter:Connect(function()
        TweenService:Create(botao, TweenInfo.new(0.15), {
            BackgroundColor3 = corHover
        }):Play()
    end)
    botao.MouseLeave:Connect(function()
        TweenService:Create(botao, TweenInfo.new(0.15), {
            BackgroundColor3 = CORES.FundoBotao
        }):Play()
    end)
end

adicionarHoverBotaoControle(btnMinimizar, CORES.AzulNeonEscuro)
adicionarHoverBotaoControle(btnFechar, CORES.Perigo)

-- ============================================================
-- MENSAGEM DE BOAS-VINDAS (Opcional)
-- ============================================================
print("[SHARK HUB] Interface carregada com sucesso.")
print("[SHARK HUB] Lembre-se: preencha os callbacks com funções reais autorizadas.")
