--[[
    Da Hood Script - Linoria Library
    Optimized & Clean
]]

-- Load Linoria Library
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Services
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

-- Local Player
local LocalPlayer = Players.LocalPlayer

-- Variables
local CashAuraEnabled = false
local CashAuraRange = 25
local ESPEnabled = false
local ShowNames = true
local ESPObjects = {}

-- Create Window
local Window = Library:CreateWindow({
    Title = 'Da Hood',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    Settings = Window:AddTab('Settings')
}

-- =============================================
-- UTILITY FUNCTIONS
-- =============================================
local function GetCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild('HumanoidRootPart')
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- =============================================
-- CASH AURA SYSTEM
-- =============================================
local function CollectCash()
    local hrp = GetHRP()
    if not hrp then return end
    
    -- Da Hood stores dropped items in Workspace.Ignored.Drop
    local droppedItems = Workspace:FindFirstChild('Ignored') and Workspace.Ignored:FindFirstChild('Drop')
    if not droppedItems then return end
    
    for _, item in pairs(droppedItems:GetChildren()) do
        -- Cash drops in Da Hood are usually Parts or Models with TouchTransmitter
        local itemPart = nil
        local itemPos = nil
        
        if item:IsA('Model') then
            -- Check for Handle or PrimaryPart
            itemPart = item:FindFirstChild('Handle') or item.PrimaryPart or item:FindFirstChildWhichIsA('BasePart')
            if itemPart then
                itemPos = itemPart.Position
            end
        elseif item:IsA('BasePart') then
            itemPart = item
            itemPos = item.Position
        end
        
        if itemPart and itemPos and GetDistance(hrp.Position, itemPos) <= CashAuraRange then
            -- Find TouchTransmitter (this is what detects pickup)
            local touchPart = itemPart
            local touchInterest = touchPart:FindFirstChildOfClass('TouchTransmitter')
            
            -- If not on main part, search children
            if not touchInterest and item:IsA('Model') then
                for _, child in pairs(item:GetDescendants()) do
                    if child:IsA('TouchTransmitter') then
                        touchInterest = child
                        touchPart = child.Parent
                        break
                    end
                end
            end
            
            if touchInterest and touchPart then
                -- Use firetouchinterest to simulate touching the cash
                firetouchinterest(hrp, touchPart, 0)
                task.wait()
                firetouchinterest(hrp, touchPart, 1)
            end
        end
    end
end

-- Cash Aura Loop
local CashAuraConnection
local function StartCashAura()
    if CashAuraConnection then return end
    CashAuraConnection = RunService.Heartbeat:Connect(function()
        if CashAuraEnabled then
            pcall(CollectCash)
        end
    end)
end

-- =============================================
-- CASH DROP SYSTEM
-- =============================================
local function DropCash(amount)
    -- Da Hood: MainEvent with "DropMoney" and amount as STRING
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local mainEvent = ReplicatedStorage:FindFirstChild('MainEvent')
    
    if mainEvent then
        pcall(function()
            mainEvent:FireServer('DropMoney', tostring(amount))
        end)
    end
end

-- =============================================
-- ESP SYSTEM (Optimized - No Lag)
-- =============================================
local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    ESPObjects[player] = {}
    
    -- Create Billboard GUI for name
    local billboard = Instance.new('BillboardGui')
    billboard.Name = 'NameESP'
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.ResetOnSpawn = false
    
    local nameLabel = Instance.new('TextLabel')
    nameLabel.Parent = billboard
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    -- Create Highlight (lightweight, no fill)
    local highlight = Instance.new('Highlight')
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    ESPObjects[player] = {
        Billboard = billboard,
        NameLabel = nameLabel,
        Highlight = highlight
    }
    
    -- Update function
    local function UpdateESP()
        if not ESPEnabled then
            billboard.Enabled = false
            highlight.Enabled = false
            return
        end
        
        local character = player.Character
        local head = character and character:FindFirstChild('Head')
        local humanoid = character and character:FindFirstChildOfClass('Humanoid')
        
        if character and head and humanoid then
            billboard.Adornee = head
            billboard.Parent = head
            billboard.Enabled = ShowNames
            
            highlight.Parent = character
            highlight.Enabled = true
            
            -- Update name with health
            local health = math.floor(humanoid.Health)
            local maxHealth = math.floor(humanoid.MaxHealth)
            nameLabel.Text = ShowNames and string.format('%s [%d/%d]', player.Name, health, maxHealth) or ''
            
            -- Color based on health
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            if healthPercent > 0.5 then
                highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 0.25 then
                highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            else
                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
            end
        else
            billboard.Enabled = false
            highlight.Enabled = false
        end
    end
    
    -- Connect to character changes
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        UpdateESP()
    end)
    
    -- Store update function
    ESPObjects[player].Update = UpdateESP
    UpdateESP()
end

local function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].Billboard then
            ESPObjects[player].Billboard:Destroy()
        end
        if ESPObjects[player].Highlight then
            ESPObjects[player].Highlight:Destroy()
        end
        ESPObjects[player] = nil
    end
end

local function RefreshAllESP()
    for player, objects in pairs(ESPObjects) do
        if objects.Update then
            pcall(objects.Update)
        end
    end
end

-- ESP Update Loop
local ESPUpdateConnection
local function StartESPLoop()
    if ESPUpdateConnection then return end
    ESPUpdateConnection = RunService.Heartbeat:Connect(function()
        if ESPEnabled then
            RefreshAllESP()
        end
    end)
end

-- Initialize ESP for existing players
local function InitializeESP()
    for _, player in pairs(Players:GetPlayers()) do
        CreateESP(player)
    end
end

-- Player connections
Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- =============================================
-- MAIN TAB UI
-- =============================================
local CashSection = Tabs.Main:AddLeftGroupbox('Cash')

CashSection:AddToggle('CashAura', {
    Text = 'Cash Aura',
    Default = false,
    Tooltip = 'Automatically collects nearby cash',
    Callback = function(Value)
        CashAuraEnabled = Value
        if Value then
            StartCashAura()
        end
    end
})

CashSection:AddSlider('CashRange', {
    Text = 'Aura Range',
    Default = 25,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        CashAuraRange = Value
    end
})

CashSection:AddButton({
    Text = 'Drop $15,000',
    Func = function()
        DropCash(15000)
        Library:Notify('Dropped $15,000!', 2)
    end,
    DoubleClick = false,
    Tooltip = 'Drops $15,000 from your wallet'
})

CashSection:AddButton({
    Text = 'Drop $5,000',
    Func = function()
        DropCash(5000)
        Library:Notify('Dropped $5,000!', 2)
    end,
    DoubleClick = false,
    Tooltip = 'Drops $5,000 from your wallet'
})

-- =============================================
-- VISUALS TAB UI
-- =============================================
local ESPSection = Tabs.Visuals:AddLeftGroupbox('ESP')

ESPSection:AddToggle('ESPToggle', {
    Text = 'Enable ESP',
    Default = false,
    Tooltip = 'Shows players through walls',
    Callback = function(Value)
        ESPEnabled = Value
        if Value then
            InitializeESP()
            StartESPLoop()
        end
        RefreshAllESP()
    end
})

ESPSection:AddToggle('ShowNames', {
    Text = 'Show Names',
    Default = true,
    Tooltip = 'Shows player names above heads',
    Callback = function(Value)
        ShowNames = Value
    end
})

-- =============================================
-- SETTINGS TAB UI
-- =============================================
local MenuSection = Tabs.Settings:AddLeftGroupbox('Menu')

MenuSection:AddButton({
    Text = 'Unload Script',
    Func = function()
        -- Cleanup
        if CashAuraConnection then
            CashAuraConnection:Disconnect()
        end
        if ESPUpdateConnection then
            ESPUpdateConnection:Disconnect()
        end
        for player, _ in pairs(ESPObjects) do
            RemoveESP(player)
        end
        Library:Unload()
    end,
    DoubleClick = true,
    Tooltip = 'Double click to unload'
})

MenuSection:AddLabel('Menu Keybind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    NoUI = true,
    Text = 'Menu Keybind'
})

Library.ToggleKeybind = Options.MenuKeybind

-- Theme and Save Manager Setup
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('DaHoodScript')
SaveManager:SetFolder('DaHoodScript/configs')

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- Load autoload config
SaveManager:LoadAutoloadConfig()

-- Notify user
Library:Notify('Da Hood Script Loaded!', 3)