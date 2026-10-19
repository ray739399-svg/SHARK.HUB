local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = "SHARK_HUB"

-- LOADING

local Loading = Instance.new("Frame")
Loading.Size = UDim2.fromScale(1,1)
Loading.BackgroundColor3 = Color3.fromRGB(5,5,10)
Loading.Parent = ScreenGui

local Text = Instance.new("TextLabel")
Text.Size = UDim2.new(0,500,0,80)
Text.Position = UDim2.new(.5,-250,.4,0)
Text.BackgroundTransparency = 1
Text.Text = "🦈 CARREGANDO SHARK HUB"
Text.TextScaled = true
Text.TextColor3 = Color3.fromRGB(0,200,255)
Text.Font = Enum.Font.GothamBlack
Text.Parent = Loading

local BarBack = Instance.new("Frame")
BarBack.Size = UDim2.new(0,400,0,20)
BarBack.Position = UDim2.new(.5,-200,.55,0)
BarBack.BackgroundColor3 = Color3.fromRGB(20,20,30)
BarBack.Parent = Loading

Instance.new("UICorner",BarBack)

local Fill = Instance.new("Frame")
Fill.Size = UDim2.new(0,0,1,0)
Fill.BackgroundColor3 = Color3.fromRGB(0,180,255)
Fill.Parent = BarBack

Instance.new("UICorner",Fill)

local Percent = Instance.new("TextLabel")
Percent.BackgroundTransparency = 1
Percent.Size = UDim2.new(0,100,0,30)
Percent.Position = UDim2.new(.5,-50,.60,0)
Percent.Text = "0%"
Percent.Font = Enum.Font.GothamBold
Percent.TextScaled = true
Percent.TextColor3 = Color3.new(1,1,1)
Percent.Parent = Loading

for i = 0,100 do
	Fill.Size = UDim2.new(i/100,0,1,0)
	Percent.Text = i.."%"
	task.wait(0.02)
end

-- MENU

local Main = Instance.new("Frame")
Main.Visible = false
Main.Size = UDim2.new(0,850,0,500)
Main.Position = UDim2.new(.5,-425,.5,-250)
Main.BackgroundColor3 = Color3.fromRGB(10,10,15)
Main.Parent = ScreenGui

Instance.new("UICorner",Main)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0,170,255)
Stroke.Parent = Main

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1,0,0,50)
Top.BackgroundColor3 = Color3.fromRGB(20,20,30)
Top.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,1,0)
Title.BackgroundTransparency = 1
Title.Text = "🦈 SHARK HUB"
Title.TextSize = 24
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.fromRGB(0,200,255)
Title.Parent = Top

local Side = Instance.new("Frame")
Side.Size = UDim2.new(0,180,1,-50)
Side.Position = UDim2.new(0,0,0,50)
Side.BackgroundColor3 = Color3.fromRGB(15,18,25)
Side.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0,5)
Layout.Parent = Side

local Pages = Instance.new("Frame")
Pages.Size = UDim2.new(1,-180,1,-50)
Pages.Position = UDim2.new(0,180,0,50)
Pages.BackgroundTransparency = 1
Pages.Parent = Main

local Frames = {}

local Tabs = {
	"HOME",
	"MOVEMENT",
	"INDEX",
	"SETTINGS",
	"ABOUT"
}

for _,Tab in ipairs(Tabs) do

	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1,-10,0,40)
	Btn.Text = Tab
	Btn.Font = Enum.Font.GothamBold
	Btn.BackgroundColor3 = Color3.fromRGB(20,24,35)
	Btn.TextColor3 = Color3.new(1,1,1)
	Btn.Parent = Side

	Instance.new("UICorner",Btn)

	local Page = Instance.new("Frame")
	Page.Size = UDim2.fromScale(1,1)
	Page.BackgroundTransparency = 1
	Page.Visible = false
	Page.Parent = Pages

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1,0,0,50)
	Label.BackgroundTransparency = 1
	Label.Text = Tab
	Label.Font = Enum.Font.GothamBlack
	Label.TextSize = 30
	Label.TextColor3 = Color3.fromRGB(0,200,255)
	Label.Parent = Page

	Frames[Tab] = Page

	Btn.MouseButton1Click:Connect(function()

		for _,v in pairs(Frames) do
			v.Visible = false
		end

		Page.Visible = true
	end)
end

Frames.HOME.Visible = true

TweenService:Create(
	Loading,
	TweenInfo.new(0.5),
	{
		BackgroundTransparency = 1
	}
):Play()

task.wait(0.5)

Loading:Destroy()

Main.Visible = true

Main.Size = UDim2.new(0,0,0,0)

TweenService:Create(
	Main,
	TweenInfo.new(.5,Enum.EasingStyle.Back),
	{
		Size = UDim2.new(0,850,0,500)
	}
):Play()
