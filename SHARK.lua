--[[
	🦈 SHARK HUB — SHARK.lua (versão compacta para Android)

	O QUE FOI PRESERVADO DO ARQUIVO ORIGINAL
	- ScreenGui "SHARK_HUB", paleta azul neon, UICorner/UIStroke, fonte Gotham e tween de abertura.

	INTEGRAÇÕES QUE DEPENDEM DO SEU JOGO (nada aqui foi inventado):
	1) Detecção de ovos: heurística por nome ("egg"/"ovo"). Se o jogo usa outro nome ou pasta,
	   ajuste CONFIG.EggNamePatterns ou defina CONFIG.EggContainer.
	2) Raridade: lida de Attribute/ValueBase (CONFIG.RarityAttributeNames). Se o jogo não expõe isso,
	   a interface mostra "indisponível". Ajuste CONFIG.RarityRank para os nomes reais do jogo.
	3) Coleta: usa ProximityPrompt/ClickDetector do ovo (precisa de fireproximityprompt/fireclickdetector
	   no executor) ou a sua função CONFIG.CustomCollect(eggInstance) se o jogo usar RemoteEvent.
	4) Teleporte de bioma: precisa de CONFIG.Biomes[i].Anchor (Vector3 ou CFrame).
	5) Esteira (a treadmill do Steal an Egg): posição salva pelo botão SALVAR ESTEIRA
	   (ou CONFIG.ConveyorCFrame). Fique em cima da esteira e toque nele.
	6) Jogo: Steal an Egg ("Roube um Ovo"). Os nomes internos de ovos/remotes não são públicos:
	   use o botão DIAGNÓSTICO (aba CONFIG) e envie o texto copiado para ajustar a integração.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local env = (type(getgenv) == "function" and getgenv()) or _G

-- Evita duplicar a interface: encerra a instância anterior antes de criar a nova.
if env.SHARK_HUB_CLEANUP then
	pcall(env.SHARK_HUB_CLEANUP)
end

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------
local CONFIG = {
	GuiName = "SHARK_HUB",
	BaseSize = Vector2.new(300, 340),
	Margin = 12,
	TopBarHeight = 34,

	-- Detecção de ovos
	EggContainer = nil, -- ex.: Workspace:FindFirstChild("Esteira"); nil = procura em todo o Workspace
	EggNamePatterns = { "egg", "ovo" },
	RarityAttributeNames = { "Rarity", "Raridade", "rarity", "raridade", "Tier" },
	BiomeAttributeNames = { "Biome", "Bioma", "biome", "bioma" },
	RarityRank = {
		common = 1, comum = 1,
		uncommon = 2, incomum = 2,
		rare = 3, raro = 3,
		epic = 4, epico = 4, ["épico"] = 4,
		legendary = 5, lendario = 5, ["lendário"] = 5,
		mythic = 6, mythical = 6, mitico = 6, ["mítico"] = 6,
		secret = 7, secreto = 7,
		eternal = 8, eterno = 8, divine = 9, divino = 9, -- ordem presumida: confirme com o DIAGNÓSTICO
	},

	-- Biomas (Keywords em minúsculas; Anchor = Vector3/CFrame opcional para teleporte)
	Biomes = {
		{ Id = "Cosmic", Label = "COSMIC", Keywords = { "cosmic", "cosmico", "cósmico" }, Anchor = nil },
		{ Id = "Cherry", Label = "FLOR DE CEREJEIRA", Keywords = { "cherry", "cerejeira", "sakura", "blossom" }, Anchor = nil },
		{ Id = "Titan", Label = "TITAN TEMPLE", Keywords = { "titan" }, Anchor = nil },
		{ Id = "AngelDemon", Label = "ANJOS E DEMÔNIOS", Keywords = { "angel", "anjo", "demon", "demonio", "demônio" }, Anchor = nil },
	},

	-- Coleta
	CustomCollect = nil, -- function(eggInstance) ... end (ex.: disparar o RemoteEvent do jogo)
	TeleportToEgg = true, -- se OFF, não se move: só aciona o ovo (funciona se o jogo permitir de longe)
	FlyToEgg = true, -- ON = voa até o ovo; OFF = teleporte instantâneo
	FlySpeed = 100, -- studs por segundo (valores muito altos podem ser punidos pelo jogo)
	MinRarityRank = 0, -- 0 = qualquer ovo; 5 = só Legendary ou mais raro; etc. (exige dado de raridade no ovo)
	Delay = 1.0,
	MinDelay = 0.3,
	MaxDelay = 5,
	ConveyorCFrame = nil, -- opcional: posição fixa da esteira
}

--------------------------------------------------------------------------------
-- TEMA / ESTADO
--------------------------------------------------------------------------------
local Theme = {
	Black = Color3.fromRGB(4, 5, 10),
	Navy = Color3.fromRGB(8, 14, 32),
	NavyLight = Color3.fromRGB(14, 26, 58),
	Neon = Color3.fromRGB(0, 200, 255),
	NeonDim = Color3.fromRGB(0, 110, 160),
	Text = Color3.fromRGB(225, 240, 255),
	Muted = Color3.fromRGB(130, 150, 180),
	Ok = Color3.fromRGB(80, 255, 170),
	Warn = Color3.fromRGB(255, 210, 80),
	Err = Color3.fromRGB(255, 95, 110),
}
local KindColor = { info = Theme.Neon, ok = Theme.Ok, warn = Theme.Warn, err = Theme.Err }

local State = {
	Collecting = false,
	RunId = 0,
	SelectedBiome = "ALL",
	BestEgg = nil,
	LastScan = {},
	ConveyorCFrame = CONFIG.ConveyorCFrame,
	Minimized = false,
	Log = {},
	Connections = {},
}

local UI = { Pages = {}, TabButtons = {}, BiomeButtons = {} }
local ScreenGui

--------------------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------------------
local function esc(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function rich(color, text)
	return string.format('<font color="#%s">%s</font>', color:ToHex(), text)
end

local function matchesAny(text, list)
	text = string.lower(text)
	for _, k in ipairs(list) do
		if string.find(text, k, 1, true) then
			return true
		end
	end
	return false
end

local function biomeById(id)
	for _, b in ipairs(CONFIG.Biomes) do
		if b.Id == id then
			return b
		end
	end
end

local function biomeLabel(id)
	if id == "ALL" then
		return "Todos"
	end
	local b = biomeById(id)
	return b and b.Label or tostring(id)
end

local function getRoot()
	local char = Player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPos(inst)
	if inst:IsA("Model") then
		return inst:GetPivot().Position
	elseif inst:IsA("BasePart") then
		return inst.Position
	end
end

local function getViewport()
	local cam = Workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(800, 400)
end

local function computeSize()
	local vp = getViewport()
	return Vector2.new(
		math.max(220, math.min(CONFIG.BaseSize.X, vp.X - CONFIG.Margin * 2)),
		math.max(200, math.min(CONFIG.BaseSize.Y, vp.Y - CONFIG.Margin * 2))
	)
end

local function getGuiParent()
	local ok, hui = pcall(function()
		return type(gethui) == "function" and gethui() or nil
	end)
	if ok and hui then
		return hui
	end
	return PlayerGui
end

local function setStatus(kind, text)
	local color = KindColor[kind] or Theme.Neon
	table.insert(State.Log, 1, string.format("[%s] %s", os.date("%H:%M:%S"), text))
	while #State.Log > 8 do
		table.remove(State.Log)
	end
	if UI.Status then
		UI.Status.Text = text
		UI.Status.TextColor3 = color
		UI.StatusDot.BackgroundColor3 = color
	end
	if UI.LogCard then
		UI.LogCard.Text = table.concat(State.Log, "\n")
	end
end

--------------------------------------------------------------------------------
-- OVOS: LEITURA DE DADOS
--------------------------------------------------------------------------------
local function readValue(inst, names)
	for _, n in ipairs(names) do
		local a = inst:GetAttribute(n)
		if a ~= nil then
			return tostring(a)
		end
		local child = inst:FindFirstChild(n)
		if child and child:IsA("ValueBase") then
			return tostring(child.Value)
		end
	end
	return nil
end

local function rarityRank(r)
	if not r then
		return 0
	end
	return CONFIG.RarityRank[string.lower(r)] or tonumber(r) or 0
end

local function detectBiome(egg)
	local chain = { egg.Name }
	local v = readValue(egg, CONFIG.BiomeAttributeNames)
	if v then
		table.insert(chain, v)
	end
	local p = egg.Parent
	while p and p ~= Workspace do
		table.insert(chain, p.Name)
		p = p.Parent
	end
	for _, b in ipairs(CONFIG.Biomes) do
		for _, name in ipairs(chain) do
			if matchesAny(name, b.Keywords) then
				return b.Id
			end
		end
	end
	return nil
end

local function isInsideCharacter(inst)
	local p = inst.Parent
	while p and p ~= Workspace do
		if Players:GetPlayerFromCharacter(p) then
			return true
		end
		p = p.Parent
	end
	return false
end

-- Pais dos ovos achados no último scan completo (permite varredura leve nos ciclos seguintes).
local EggRoots = nil

-- Varredura sem criar uma lista gigante de todos os objetos (usa pouca memória):
-- percorre por pilha, não desce dentro de ovos nem de personagens e cede o turno de tempos em tempos.
-- light = true: só olha as pastas onde ovos foram achados no último scan completo.
local function scanEggs(light)
	local top = CONFIG.EggContainer or Workspace
	if top.Parent == nil then
		top = Workspace
	end
	local roots = { top }
	if light and EggRoots and #EggRoots > 0 then
		roots = {}
		for _, r in ipairs(EggRoots) do
			if r.Parent then
				table.insert(roots, r)
			end
		end
		if #roots == 0 then
			roots = { top }
		end
	end

	local found, parents, parentSet = {}, {}, {}
	local visited = 0
	for _, root in ipairs(roots) do
		local stack = root:GetChildren()
		while #stack > 0 do
			local inst = table.remove(stack)
			visited = visited + 1
			if visited % 3000 == 0 then
				task.wait()
			end
			if (inst:IsA("Model") or inst:IsA("BasePart")) and matchesAny(inst.Name, CONFIG.EggNamePatterns) then
				if not isInsideCharacter(inst) then
					local pos = getPos(inst)
					if pos then
						local rarity = readValue(inst, CONFIG.RarityAttributeNames)
						table.insert(found, {
							Instance = inst,
							Name = inst.Name,
							Rarity = rarity,
							Rank = rarityRank(rarity),
							Biome = detectBiome(inst),
							Position = pos,
							Distance = math.huge,
						})
						local par = inst.Parent
						if par and not parentSet[par] then
							parentSet[par] = true
							table.insert(parents, par)
						end
					end
				end
			elseif not (inst:IsA("Model") and Players:GetPlayerFromCharacter(inst)) then
				for _, c in ipairs(inst:GetChildren()) do
					table.insert(stack, c)
				end
			end
		end
	end

	if not light then
		EggRoots = (#parents > 0 and #parents <= 60) and parents or nil
	end
	return found
end

-- Melhor ovo = maior raridade; empate = o mais próximo. Sem raridade = o mais próximo.
local function pickBest(list, biomeId)
	local root = getRoot()
	local best
	local info = { anyRarity = false, unknown = nil, count = 0 }
	for _, e in ipairs(list) do
		if e.Instance.Parent and (biomeId == "ALL" or e.Biome == biomeId) and e.Rank >= CONFIG.MinRarityRank then
			e.Position = getPos(e.Instance) or e.Position
			e.Distance = root and (e.Position - root.Position).Magnitude or math.huge
			info.count = info.count + 1
			if e.Rarity then
				info.anyRarity = true
				if e.Rank == 0 and not info.unknown then
					info.unknown = e.Rarity
				end
			end
			if not best or e.Rank > best.Rank or (e.Rank == best.Rank and e.Distance < best.Distance) then
				best = e
			end
		end
	end
	return best, info
end

local function raritySummary(list, biomeId)
	local counts, ranks, none, total = {}, {}, 0, 0
	for _, e in ipairs(list) do
		if e.Instance.Parent and (biomeId == "ALL" or e.Biome == biomeId) then
			total = total + 1
			if e.Rarity then
				counts[e.Rarity] = (counts[e.Rarity] or 0) + 1
				ranks[e.Rarity] = e.Rank
			else
				none = none + 1
			end
		end
	end
	if total == 0 then
		return "Sem ovos no último scan."
	end
	local names = {}
	for r in pairs(counts) do
		table.insert(names, r)
	end
	table.sort(names, function(a, b)
		if ranks[a] ~= ranks[b] then
			return ranks[a] > ranks[b]
		end
		return a < b
	end)
	if #names == 0 then
		return string.format("Raridade indisponível (%d ovos sem dado).", total)
	end
	local parts = {}
	for _, r in ipairs(names) do
		table.insert(parts, esc(r) .. " ×" .. counts[r])
	end
	if none > 0 then
		table.insert(parts, "sem raridade ×" .. none)
	end
	return table.concat(parts, " · ")
end

local function capabilityText()
	local function yn(v)
		return v and "sim" or "não"
	end
	local anchors = 0
	for _, b in ipairs(CONFIG.Biomes) do
		if b.Anchor then
			anchors = anchors + 1
		end
	end
	return rich(Theme.Neon, "<b>INTEGRAÇÕES</b>")
		.. "\nCustomCollect: " .. yn(type(CONFIG.CustomCollect) == "function")
		.. "\nfireproximityprompt: " .. yn(typeof(fireproximityprompt) == "function")
		.. "\nfireclickdetector: " .. yn(typeof(fireclickdetector) == "function")
		.. "\nAnchors de bioma: " .. anchors .. "/" .. #CONFIG.Biomes
		.. "\nEsteira salva: " .. yn(State.ConveyorCFrame ~= nil)
end

--------------------------------------------------------------------------------
-- ATUALIZAÇÃO DA INTERFACE (informações)
--------------------------------------------------------------------------------
local function refreshInfo()
	-- Cartão do melhor ovo
	if UI.EggCard then
		local e = State.BestEgg
		local head = rich(Theme.Neon, "<b>MELHOR OVO</b>")
		if not e then
			UI.EggCard.Text = head .. "\nNenhum ovo selecionado.\nUse SCAN MELHOR OVO."
		else
			local dist = (e.Distance < math.huge) and (math.floor(e.Distance) .. " studs") or "?"
			UI.EggCard.Text = head
				.. "\nOvo: " .. esc(e.Name)
				.. "\nRaridade: " .. (e.Rarity and esc(e.Rarity) or "indisponível")
				.. "\nBioma: " .. (e.Biome and biomeLabel(e.Biome) or "não identificado") .. " · " .. dist
		end
	end

	if UI.RarityCard then
		UI.RarityCard.Text = rich(Theme.Neon, "<b>RARIDADES (último scan)</b>") .. "\n"
			.. raritySummary(State.LastScan, State.SelectedBiome)
	end

	-- Biomas: contagem por bioma + destaque da seleção
	local counts = {}
	for _, e in ipairs(State.LastScan) do
		if e.Instance.Parent then
			local k = e.Biome or "?"
			counts[k] = (counts[k] or 0) + 1
		end
	end
	local hasScan = #State.LastScan > 0
	for _, b in ipairs(CONFIG.Biomes) do
		local btn = UI.BiomeButtons[b.Id]
		if btn then
			btn.Text = b.Label .. (hasScan and ("  (" .. (counts[b.Id] or 0) .. ")") or "")
		end
	end
	for id, btn in pairs(UI.BiomeButtons) do
		local on = (id == State.SelectedBiome)
		btn.BackgroundColor3 = on and Theme.NeonDim or Theme.NavyLight
		btn.TextColor3 = on and Color3.new(1, 1, 1) or Theme.Text
	end
	if UI.BiomeCard then
		local inBiome = 0
		for _, e in ipairs(State.LastScan) do
			if e.Instance.Parent and (State.SelectedBiome == "ALL" or e.Biome == State.SelectedBiome) then
				inBiome = inBiome + 1
			end
		end
		local b = biomeById(State.SelectedBiome)
		UI.BiomeCard.Text = rich(Theme.Neon, "<b>BIOMA: " .. esc(biomeLabel(State.SelectedBiome)) .. "</b>")
			.. "\nOvos no scan: " .. (hasScan and inBiome or "sem scan")
			.. "\nTeleporte: " .. ((State.SelectedBiome ~= "ALL" and b and b.Anchor) and "configurado" or "indisponível")
			.. "\n" .. raritySummary(State.LastScan, State.SelectedBiome)
	end

	if UI.CapsCard then
		UI.CapsCard.Text = capabilityText()
	end
end

local function updateButtons()
	local c = State.Collecting
	if UI.BtnGrab then
		UI.BtnGrab.TextTransparency = c and 0.55 or 0
	end
	if UI.BtnStop then
		UI.BtnStop.TextTransparency = c and 0 or 0.55
	end
	if UI.Title then
		UI.Title.Text = c and "🦈 SHARK · COLETANDO" or "🦈 SHARK HUB"
	end
end

local function updateWindowButtons()
	if UI.BtnMin then
		UI.BtnMin.TextTransparency = State.Minimized and 0.6 or 0
		UI.BtnRestore.TextTransparency = State.Minimized and 0 or 0.6
	end
end

--------------------------------------------------------------------------------
-- AÇÕES
--------------------------------------------------------------------------------
local function doScan(light)
	local list = scanEggs(light)
	State.LastScan = list
	local best, info = pickBest(list, State.SelectedBiome)
	State.BestEgg = best
	refreshInfo()
	return list, best, info
end

local function teleportTo(pos)
	local root = getRoot()
	if not root then
		return false
	end
	root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	return true
end

local function teleportCFrame(cf)
	local root = getRoot()
	if not root then
		return false
	end
	root.CFrame = cf
	return true
end

local function actionScan()
	local list, best, info = doScan()
	if #list == 0 then
		setStatus("warn", "Nenhum ovo encontrado. Ajuste CONFIG.EggContainer.")
	elseif not best then
		setStatus("warn", string.format("%d ovos, nenhum atende ao filtro (bioma %s / raridade).", #list, biomeLabel(State.SelectedBiome)))
	elseif not info.anyRarity then
		setStatus("warn", string.format("%d ovos; raridade indisponível. Usando o mais próximo.", info.count))
	elseif info.unknown then
		setStatus("warn", "Raridade '" .. info.unknown .. "' fora de CONFIG.RarityRank.")
	else
		setStatus("ok", string.format("Melhor: %s (%s) · %d ovos", best.Name, best.Rarity, info.count))
	end
end

local function triggerCollect(egg)
	if type(CONFIG.CustomCollect) == "function" then
		local ok, err = pcall(CONFIG.CustomCollect, egg.Instance)
		if ok then
			return true, "CustomCollect"
		end
		return false, "CustomCollect falhou: " .. tostring(err)
	end
	local prompt = egg.Instance:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		if typeof(fireproximityprompt) ~= "function" then
			return false, "Executor sem fireproximityprompt."
		end
		local ok, err = pcall(fireproximityprompt, prompt)
		return ok, ok and "ProximityPrompt" or ("Erro no prompt: " .. tostring(err))
	end
	local click = egg.Instance:FindFirstChildWhichIsA("ClickDetector", true)
	if click then
		if typeof(fireclickdetector) ~= "function" then
			return false, "Executor sem fireclickdetector."
		end
		local ok, err = pcall(fireclickdetector, click)
		return ok, ok and "ClickDetector" or ("Erro no click: " .. tostring(err))
	end
	return false, "Ovo sem prompt/click. Defina CONFIG.CustomCollect."
end

local function saveConveyor(auto)
	local root = getRoot()
	if not root then
		setStatus("err", "Personagem não encontrado.")
		return false
	end
	State.ConveyorCFrame = root.CFrame
	refreshInfo()
	setStatus("ok", auto and "Posição da esteira salva automaticamente." or "Posição da esteira salva.")
	return true
end

local function stopCollecting(reason)
	if not State.Collecting then
		setStatus("info", "Nada em execução. A coleta já está parada.")
		return false
	end
	State.Collecting = false
	State.RunId = State.RunId + 1
	updateButtons()
	setStatus("ok", reason or "Coleta parada.")
	return true
end

-- Voa em linha reta até o ovo (interrompe se a coleta for parada ou passar de 20s).
local function flyTo(inst, id)
	local deadline = os.clock() + 20
	while State.Collecting and State.RunId == id do
		local root = getRoot()
		if not root or not inst.Parent then
			return false
		end
		local target = getPos(inst)
		if not target then
			return false
		end
		local offset = (target + Vector3.new(0, 3, 0)) - root.Position
		local dist = offset.Magnitude
		if dist < 4 then
			return true
		end
		if os.clock() > deadline then
			return false
		end
		local dt = RunService.Heartbeat:Wait()
		local step = math.min(dist, CONFIG.FlySpeed * dt)
		root.CFrame = root.CFrame + offset.Unit * step
		root.AssemblyLinearVelocity = Vector3.zero
	end
	return false
end

local function startCollecting()
	if State.Collecting then
		setStatus("warn", "Já está pegando ovos. Use PARAR DE PEGAR.")
		return
	end
	if not getRoot() then
		setStatus("err", "Personagem não encontrado.")
		return
	end
	local list = doScan()
	if #list == 0 then
		setStatus("warn", "Nenhum ovo encontrado. Coleta não iniciada.")
		return
	end
	if not State.ConveyorCFrame then
		local root = getRoot()
		State.ConveyorCFrame = root.CFrame
		refreshInfo()
	end

	State.Collecting = true
	State.RunId = State.RunId + 1
	local id = State.RunId
	updateButtons()
	setStatus("ok", "Coleta iniciada.")

	task.spawn(function()
		local triggered, fails, cycle = 0, 0, 0
		while State.Collecting and State.RunId == id do
			cycle = cycle + 1
			local _, best = doScan(cycle % 10 ~= 1) -- scan completo a cada 10 ciclos
			if not (State.Collecting and State.RunId == id) then
				break
			end
			if not best then
				setStatus("warn", CONFIG.MinRarityRank > 0 and "Aguardando ovo raro…" or "Aguardando ovos…")
			else
				if CONFIG.TeleportToEgg then
					local moved
					if CONFIG.FlyToEgg then
						moved = flyTo(best.Instance, id)
							else
						 = teleportTo(best.Position)
						task.wait(0.15)
					end
					if State.RunId ~= id then
						break
					end
					if not moved then
						setStatus("err", "Não consegui chegar ao ovo.")
					end
				end
				local ok, how = triggerCollect(best)
				if State.RunId ~= id then
					break
				end
				if ok then
					fails = 0
					triggered = triggered + 1
					setStatus("ok", string.format("#%d acionado: %s via %s", triggered, best.Name, how))
				else
					fails = fails + 1
					setStatus("err", how)
					if fails >= 3 then
						State.Collecting = false
						State.RunId = State.RunId + 1
						updateButtons()
						setStatus("err", "Coleta parada após 3 falhas. " .. how)
						break
					end
				end
			end
			task.wait(CONFIG.Delay)
		end
	end)
end

local function returnToConveyor()
	local wasCollecting = State.Collecting
	if wasCollecting then
		State.Collecting = false
		State.RunId = State.RunId + 1
		updateButtons()
	end
	if not State.ConveyorCFrame then
		setStatus("warn", "Esteira não salva. Use SALVAR ESTEIRA em CONFIG.")
		return
	end
	if teleportCFrame(State.ConveyorCFrame) then
		setStatus("ok", wasCollecting and "Coleta parada e voltou à esteira." or "Voltou para a esteira.")
	else
		setStatus("err", "Personagem indisponível.")
	end
end

local function selectBiome(id)
	State.SelectedBiome = id
	if #State.LastScan > 0 then
		State.BestEgg = pickBest(State.LastScan, id)
	end
	refreshInfo()
	setStatus("ok", "Bioma selecionado: " .. biomeLabel(id))
end

local function goToBiome()
	if State.SelectedBiome == "ALL" then
		setStatus("warn", "Selecione um bioma específico primeiro.")
		return
	end
	local b = biomeById(State.SelectedBiome)
	if not b or not b.Anchor then
		setStatus("warn", "Sem Anchor para " .. biomeLabel(State.SelectedBiome) .. ". Veja CONFIG.Biomes.")
		return
	end
	local ok
	if typeof(b.Anchor) == "CFrame" then
		ok = teleportCFrame(b.Anchor)
	else
		ok = teleportTo(b.Anchor)
	end
	if ok then
		setStatus("ok", "Teleportado para " .. biomeLabel(b.Id))
	else
		setStatus("err", "Personagem indisponível.")
	end
end

-- Lista o que o script realmente enxerga no jogo (ovos, atributos, prompts e remotes
-- com nomes relacionados). Serve para ajustar a integração sem chutar nomes.
local function actionDiagnose()
	local list = scanEggs()
	local lines = { "== DIAGNOSTICO SHARK ==", "Ovos encontrados: " .. #list }
	for i, e in ipairs(list) do
		if i > 12 then
			break
		end
		local inst = e.Instance
		local attrs = {}
		for k, v in pairs(inst:GetAttributes()) do
			table.insert(attrs, k .. "=" .. tostring(v))
		end
		table.insert(lines, string.format(
			"%d) %s [%s] raridade=%s bioma=%s prompt=%s click=%s attrs={%s}",
			i, inst:GetFullName(), inst.ClassName, tostring(e.Rarity), tostring(e.Biome),
			tostring(inst:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil),
			tostring(inst:FindFirstChildWhichIsA("ClickDetector", true) ~= nil),
			table.concat(attrs, ",")
		))
	end
	local keys = { "egg", "ovo", "steal", "grab", "pick", "collect", "hatch", "carry" }
	local remotes = {}
	for _, inst in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
		if (inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction")) and matchesAny(inst.Name, keys) then
			table.insert(remotes, inst.ClassName .. ": " .. inst:GetFullName())
			if #remotes >= 25 then
				break
			end
		end
	end
	table.insert(lines, "Remotes relacionados: " .. #remotes)
	for _, r in ipairs(remotes) do
		table.insert(lines, r)
	end
	local text = table.concat(lines, "\n")
	if type(setclipboard) == "function" and pcall(setclipboard, text) then
		setStatus("ok", string.format("Diagnóstico copiado (%d ovos). Cole no chat.", #list))
	else
		print(text)
		setStatus("warn", "Sem setclipboard: diagnóstico impresso no console.")
	end
end

--------------------------------------------------------------------------------
-- HELPERS DE INTERFACE
--------------------------------------------------------------------------------
local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = inst
	return c
end

local function stroke(inst, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = inst
	return s
end

local function makeButton(parent, text, order, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -4, 0, 32)
	b.LayoutOrder = order
	b.BackgroundColor3 = Theme.NavyLight
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = Theme.Text
	b.Parent = parent
	corner(b, 6)
	stroke(b, Theme.Neon, 1, 0.5)
	b.Activated:Connect(function()
		local ok, err = pcall(onClick)
		if not ok then
			setStatus("err", "Erro: " .. tostring(err))
		end
	end)
	return b
end

local function makeCard(parent, order, height)
	local f = Instance.new("TextLabel")
	f.Size = UDim2.new(1, -4, 0, height)
	f.LayoutOrder = order
	f.BackgroundColor3 = Theme.Black
	f.BackgroundTransparency = 0.15
	f.Text = ""
	f.RichText = true
	f.TextWrapped = true
	f.TextXAlignment = Enum.TextXAlignment.Left
	f.TextYAlignment = Enum.TextYAlignment.Top
	f.Font = Enum.Font.Gotham
	f.TextSize = 12
	f.TextColor3 = Theme.Text
	f.Parent = parent
	corner(f, 6)
	stroke(f, Theme.NeonDim, 1, 0.3)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	pad.Parent = f
	return f
end

local function makePage(name, container)
	local sf = Instance.new("ScrollingFrame")
	sf.Size = UDim2.fromScale(1, 1)
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 3
	sf.ScrollBarImageColor3 = Theme.Neon
	sf.CanvasSize = UDim2.new()
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.Visible = false
	sf.Parent = container
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = sf
	UI.Pages[name] = sf
	return sf
end

local function selectTab(name)
	for n, page in pairs(UI.Pages) do
		page.Visible = (n == name)
	end
	for n, b in pairs(UI.TabButtons) do
		local on = (n == name)
		b.BackgroundColor3 = on and Theme.NeonDim or Theme.NavyLight
		b.TextColor3 = on and Color3.new(1, 1, 1) or Theme.Muted
	end
end

local function makeDraggable(handle, target)
	local dragging, dragInput, startPointer, startPos = false, nil, nil, nil
	handle.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
			startPointer = input.Position
			startPos = target.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					conn:Disconnect()
				end
			end)
		end
	end)
	table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - startPointer
			local vp = getViewport()
			local w = target.AbsoluteSize.X
			local x = math.clamp(startPos.X.Offset + d.X, -(w - 80), vp.X - 80)
			local y = math.clamp(startPos.Y.Offset + d.Y, 0, vp.Y - CONFIG.TopBarHeight)
			target.Position = UDim2.fromOffset(x, y)
		end
	end))
end

--------------------------------------------------------------------------------
-- LIMPEZA / FECHAR
--------------------------------------------------------------------------------
local function cleanup()
	State.Collecting = false
	State.RunId = State.RunId + 1
	for _, c in ipairs(State.Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	State.Connections = {}
	if ScreenGui then
		pcall(function()
			ScreenGui:Destroy()
		end)
	end
	if env.SHARK_HUB_CLEANUP == cleanup then
		env.SHARK_HUB_CLEANUP = nil
	end
end
env.SHARK_HUB_CLEANUP = cleanup

--------------------------------------------------------------------------------
-- CONSTRUÇÃO DA INTERFACE (uma única ScreenGui)
--------------------------------------------------------------------------------
for _, parent in ipairs({ PlayerGui, getGuiParent() }) do
	local old = parent:FindFirstChild(CONFIG.GuiName)
	if old then
		old:Destroy()
	end
end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = CONFIG.GuiName
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 50

local fullSize = computeSize()
local vp0 = getViewport()

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Visible = false
Main.ClipsDescendants = true
Main.Size = UDim2.fromOffset(fullSize.X, fullSize.Y)
Main.Position = UDim2.fromOffset((vp0.X - fullSize.X) / 2, (vp0.Y - fullSize.Y) / 2)
Main.BackgroundColor3 = Theme.Navy
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
corner(Main, 10)
stroke(Main, Theme.Neon, 1.5, 0.1)
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(Theme.NavyLight, Theme.Black)
grad.Rotation = 90
grad.Parent = Main

local function applySize()
	local s = computeSize()
	Main.Size = UDim2.fromOffset(s.X, State.Minimized and CONFIG.TopBarHeight or s.Y)
end

-- Barra superior
local Top = Instance.new("Frame")
Top.Name = "Top"
Top.Size = UDim2.new(1, 0, 0, CONFIG.TopBarHeight)
Top.BackgroundColor3 = Theme.Black
Top.BackgroundTransparency = 0.2
Top.BorderSizePixel = 0
Top.Active = true
Top.Parent = Main

UI.Title = Instance.new("TextLabel")
UI.Title.Size = UDim2.new(1, -(4 * 26 + 3 * 4 + 14), 1, 0)
UI.Title.Position = UDim2.fromOffset(10, 0)
UI.Title.BackgroundTransparency = 1
UI.Title.Text = "🦈 SHARK HUB"
UI.Title.TextXAlignment = Enum.TextXAlignment.Left
UI.Title.Font = Enum.Font.GothamBlack
UI.Title.TextSize = 14
UI.Title.TextColor3 = Theme.Neon
UI.Title.Parent = Top

local Controls = Instance.new("Frame")
Controls.AnchorPoint = Vector2.new(1, 0.5)
Controls.Position = UDim2.new(1, -6, 0.5, 0)
Controls.Size = UDim2.fromOffset(4 * 26 + 3 * 4, 26)
Controls.BackgroundTransparency = 1
Controls.Parent = Top
local cl = Instance.new("UIListLayout")
cl.FillDirection = Enum.FillDirection.Horizontal
cl.Padding = UDim.new(0, 4)
cl.SortOrder = Enum.SortOrder.LayoutOrder
cl.VerticalAlignment = Enum.VerticalAlignment.Center
cl.Parent = Controls

local function makeWindowButton(text, order, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(26, 26)
	b.LayoutOrder = order
	b.BackgroundColor3 = Theme.NavyLight
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = color or Theme.Neon
	b.Parent = Controls
	corner(b, 6)
	stroke(b, color or Theme.Neon, 1, 0.5)
	return b
end

local BtnDrag = makeWindowButton("✥", 1)
UI.BtnMin = makeWindowButton("–", 2)
UI.BtnRestore = makeWindowButton("□", 3)
local BtnClose = makeWindowButton("X", 4, Theme.Err)

makeDraggable(Top, Main)
makeDraggable(BtnDrag, Main)

-- Linha de carregamento discreta (animação curta)
local LoaderLine = Instance.new("Frame")
LoaderLine.Size = UDim2.new(0, 0, 0, 2)
LoaderLine.Position = UDim2.fromOffset(0, CONFIG.TopBarHeight)
LoaderLine.BackgroundColor3 = Theme.Neon
LoaderLine.BorderSizePixel = 0
LoaderLine.ZIndex = 5
LoaderLine.Parent = Main

-- Corpo
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Position = UDim2.fromOffset(0, CONFIG.TopBarHeight + 2)
Body.Size = UDim2.new(1, 0, 1, -(CONFIG.TopBarHeight + 2))
Body.BackgroundTransparency = 1
Body.Parent = Main
local bp = Instance.new("UIPadding")
bp.PaddingTop, bp.PaddingBottom = UDim.new(0, 6), UDim.new(0, 8)
bp.PaddingLeft, bp.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
bp.Parent = Body

-- Abas
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 28)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Body
local tl = Instance.new("UIListLayout")
tl.FillDirection = Enum.FillDirection.Horizontal
tl.Padding = UDim.new(0, 4)
tl.SortOrder = Enum.SortOrder.LayoutOrder
tl.Parent = TabBar

local PagesHolder = Instance.new("Frame")
PagesHolder.Position = UDim2.fromOffset(0, 34)
PagesHolder.Size = UDim2.new(1, 0, 1, -(34 + 40))
PagesHolder.BackgroundTransparency = 1
PagesHolder.Parent = Body

-- Barra de status (sempre visível)
local StatusBar = Instance.new("Frame")
StatusBar.AnchorPoint = Vector2.new(0, 1)
StatusBar.Position = UDim2.new(0, 0, 1, 0)
StatusBar.Size = UDim2.new(1, 0, 0, 34)
StatusBar.BackgroundColor3 = Theme.Black
StatusBar.BackgroundTransparency = 0.1
StatusBar.Parent = Body
corner(StatusBar, 6)
stroke(StatusBar, Theme.NeonDim, 1, 0.3)

UI.StatusDot = Instance.new("Frame")
UI.StatusDot.Size = UDim2.fromOffset(8, 8)
UI.StatusDot.AnchorPoint = Vector2.new(0, 0.5)
UI.StatusDot.Position = UDim2.new(0, 8, 0.5, 0)
UI.StatusDot.BackgroundColor3 = Theme.Neon
UI.StatusDot.BorderSizePixel = 0
UI.StatusDot.Parent = StatusBar
corner(UI.StatusDot, 4)

UI.Status = Instance.new("TextLabel")
UI.Status.Position = UDim2.fromOffset(22, 0)
UI.Status.Size = UDim2.new(1, -28, 1, 0)
UI.Status.BackgroundTransparency = 1
UI.Status.Text = "Iniciando…"
UI.Status.TextWrapped = true
UI.Status.TextTruncate = Enum.TextTruncate.AtEnd
UI.Status.TextXAlignment = Enum.TextXAlignment.Left
UI.Status.Font = Enum.Font.GothamMedium
UI.Status.TextSize = 12
UI.Status.TextColor3 = Theme.Neon
UI.Status.Parent = StatusBar

-- Páginas
local TAB_ORDER = { "OVOS", "BIOMAS", "CONFIG" }
for i, name in ipairs(TAB_ORDER) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1 / 3, -3, 1, 0)
	b.LayoutOrder = i
	b.Text = name
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.BackgroundColor3 = Theme.NavyLight
	b.TextColor3 = Theme.Muted
	b.Parent = TabBar
	corner(b, 6)
	b.Activated:Connect(function()
		selectTab(name)
	end)
	UI.TabButtons[name] = b
	makePage(name, PagesHolder)
end

-- Aba OVOS
do
	local page = UI.Pages.OVOS
	UI.EggCard = makeCard(page, 1, 78)
	makeButton(page, "SCAN MELHOR OVO", 2, actionScan)
	UI.BtnGrab = makeButton(page, "PEGAR OVO", 3, startCollecting)
	UI.BtnStop = makeButton(page, "PARAR DE PEGAR", 4, function()
		stopCollecting("Coleta parada.")
	end)
	makeButton(page, "VOLTAR PARA ESTEIRA", 5, returnToConveyor)
	UI.RarityCard = makeCard(page, 6, 74)
end

-- Aba BIOMAS
do
	local page = UI.Pages.BIOMAS
	UI.BiomeButtons.ALL = makeButton(page, "TODOS (SEM FILTRO)", 1, function()
		selectBiome("ALL")
	end)
	for i, b in ipairs(CONFIG.Biomes) do
		UI.BiomeButtons[b.Id] = makeButton(page, b.Label, 1 + i, function()
			selectBiome(b.Id)
		end)
	end
	makeButton(page, "IR PARA BIOMA SELECIONADO", 10, goToBiome)
	UI.BiomeCard = makeCard(page, 11, 96)
end

-- Aba CONFIG
do
	local page = UI.Pages.CONFIG

	local toggle
	toggle = makeButton(page, "", 1, function()
		CONFIG.TeleportToEgg = not CONFIG.TeleportToEgg
		toggle.Text = "TELEPORTAR ATÉ O OVO: " .. (CONFIG.TeleportToEgg and "ON" or "OFF")
		setStatus("ok", "Teleportar até o ovo: " .. (CONFIG.TeleportToEgg and "ligado" or "desligado"))
	end)
	toggle.Text = "TELEPORTAR ATÉ O OVO: " .. (CONFIG.TeleportToEgg and "ON" or "OFF")

	-- Movimento até o ovo (voar ou teleporte)
	local flyToggle
	flyToggle = makeButton(page, "", 0, function()
		CONFIG.FlyToEgg = not CONFIG.FlyToEgg
		flyToggle.Text = "MOVIMENTO: " .. (CONFIG.FlyToEgg and "VOAR" or "TELEPORTE")
		setStatus("ok", "Movimento até o ovo: " .. (CONFIG.FlyToEgg and "voar" or "teleporte"))
	end)
	flyToggle.Text = "MOVIMENTO: " .. (CONFIG.FlyToEgg and "VOAR" or "TELEPORTE")

	-- Raridade mínima para o auto farm
	local levels = {
		{ 0, "QUALQUER" }, { 5, "LEGENDARY+" }, { 6, "MYTHIC+" },
		{ 7, "SECRET+" }, { 8, "ETERNAL+" }, { 9, "DIVINE" },
	}
	local levelIdx = 1
	for i, l in ipairs(levels) do
		if l[1] == CONFIG.MinRarityRank then
			levelIdx = i
		end
	end
	local rarBtn
	rarBtn = makeButton(page, "", 1, function()
		levelIdx = levelIdx % #levels + 1
		CONFIG.MinRarityRank = levels[levelIdx][1]
		rarBtn.Text = "RARIDADE MÍNIMA: " .. levels[levelIdx][2]
		if #State.LastScan > 0 then
			State.BestEgg = pickBest(State.LastScan, State.SelectedBiome)
			refreshInfo()
		end
		setStatus("ok", "Raridade mínima: " .. levels[levelIdx][2] .. " (exige dado de raridade no ovo)")
	end)
	rarBtn.Text = "RARIDADE MÍNIMA: " .. levels[levelIdx][2]

	-- Intervalo da coleta
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 32)
	row.LayoutOrder = 2
	row.BackgroundTransparency = 1
	row.Parent = page

	local delayLabel = Instance.new("TextLabel")
	delayLabel.Position = UDim2.fromOffset(46, 0)
	delayLabel.Size = UDim2.new(1, -92, 1, 0)
	delayLabel.BackgroundTransparency = 1
	delayLabel.Font = Enum.Font.GothamBold
	delayLabel.TextSize = 13
	delayLabel.TextColor3 = Theme.Text
	delayLabel.Parent = row

	local function refreshDelay()
		delayLabel.Text = string.format("INTERVALO: %.1fs", CONFIG.Delay)
	end
	refreshDelay()

	local function changeDelay(step)
		local v = math.floor((CONFIG.Delay + step) * 10 + 0.5) / 10
		CONFIG.Delay = math.clamp(v, CONFIG.MinDelay, CONFIG.MaxDelay)
		refreshDelay()
		setStatus("ok", string.format("Intervalo da coleta: %.1fs", CONFIG.Delay))
	end

	local function stepButton(text, anchorX, step)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(anchorX, 0)
		b.Position = UDim2.new(anchorX, 0, 0, 0)
		b.Size = UDim2.new(0, 40, 1, 0)
		b.BackgroundColor3 = Theme.NavyLight
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 16
		b.TextColor3 = Theme.Neon
		b.Parent = row
		corner(b, 6)
		stroke(b, Theme.Neon, 1, 0.5)
		b.Activated:Connect(function()
			changeDelay(step)
		end)
	end
	stepButton("-", 0, -0.1)
	stepButton("+", 1, 0.1)

	makeButton(page, "SALVAR ESTEIRA (POSIÇÃO ATUAL)", 3, function()
		saveConveyor(false)
	end)
	makeButton(page, "DIAGNÓSTICO (COPIAR DADOS DO JOGO)", 4, actionDiagnose)
	UI.CapsCard = makeCard(page, 5, 96)
	UI.LogCard = makeCard(page, 6, 130)
	UI.LogCard.RichText = false
	UI.LogCard.TextSize = 11
	UI.LogCard.TextColor3 = Theme.Muted
	UI.LogCard.Text = "Log de operações aparecerá aqui."
end

-- Botões da janela
UI.BtnMin.Activated:Connect(function()
	if State.Minimized then
		setStatus("info", "Já está minimizado.")
		return
	end
	State.Minimized = true
	Body.Visible = false
	TweenService:Create(Main, TweenInfo.new(0.18), { Size = UDim2.fromOffset(Main.AbsoluteSize.X, CONFIG.TopBarHeight) }):Play()
	updateWindowButtons()
	setStatus("info", "Painel minimizado.")
end)

UI.BtnRestore.Activated:Connect(function()
	if not State.Minimized then
		setStatus("info", "Painel já está restaurado.")
		return
	end
	State.Minimized = false
	Body.Visible = true
	local s = computeSize()
	TweenService:Create(Main, TweenInfo.new(0.18), { Size = UDim2.fromOffset(s.X, s.Y) }):Play()
	updateWindowButtons()
	setStatus("info", "Painel restaurado.")
end)

BtnClose.Activated:Connect(function()
	cleanup()
end)

-- Reajusta ao mudar a tela (rotação, etc.)
do
	local cam = Workspace.CurrentCamera
	if cam then
		table.insert(State.Connections, cam:GetPropertyChangedSignal("ViewportSize"):Connect(applySize))
	end
end

ScreenGui.Parent = getGuiParent()

selectTab("OVOS")
refreshInfo()
updateButtons()
updateWindowButtons()

-- Animação de entrada curta e discreta (~0.8s), sem tela cheia
task.spawn(function()
	local s = computeSize()
	Main.Size = UDim2.fromOffset(s.X * 0.9, s.Y * 0.9)
	Main.Visible = true
	TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(s.X, s.Y),
	}):Play()
	local t = TweenService:Create(LoaderLine, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
		Size = UDim2.new(1, 0, 0, 2),
	})
	t:Play()
	t.Completed:Wait()
	local f = TweenService:Create(LoaderLine, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
	f:Play()
	f.Completed:Wait()
	LoaderLine:Destroy()
	setStatus("info", "Pronto. Use SCAN MELHOR OVO.")
end)
