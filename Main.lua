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
local UserInputService = game:GetService('UserInputService')

-- Local Player
local LocalPlayer = Players.LocalPlayer

-- Variables
local CashAuraEnabled = false
local CashAuraRange = 25
local CashDropEnabled = false
local CashDropDelay = 5
local ESPEnabled = false
local ShowNames = true
local MoneyESPEnabled = false
local ESPColor = Color3.fromRGB(255, 0, 0)
local ESPTextColor = Color3.fromRGB(255, 255, 255)
local ESPTextSize = 14
local UseHealthColor = true
local ESPObjects = {}
local MoneyESPObjects = {}

-- CFrame Speed Variables
local CFrameSpeedEnabled = false
local CFrameSpeedValue = 1.5

-- CFrame Fly Variables
local CFrameFlyEnabled = false
local CFrameFlySpeed = 50
local FlyBodyGyro = nil
local FlyBodyVelocity = nil

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
local CashAuraConnection

local function CollectCash()
    local hrp = GetHRP()
    if not hrp then return end
    
    local myPosition = hrp.Position
    
    -- Da Hood stores dropped items in Workspace.Ignored.Drop
    local droppedItems = Workspace:FindFirstChild('Ignored') and Workspace.Ignored:FindFirstChild('Drop')
    if not droppedItems then return end
    
    for _, item in pairs(droppedItems:GetChildren()) do
        if not CashAuraEnabled then break end
        
        -- Cash in Da Hood is called "MoneyDrop"
        if item.Name == 'MoneyDrop' and item:IsA('BasePart') then
            local cashPosition = item.Position
            local distance = (myPosition - cashPosition).Magnitude
            
            -- Only pick up if within range
            if distance <= CashAuraRange then
                local clickDetector = item:FindFirstChildOfClass('ClickDetector')
                if clickDetector then
                    fireclickdetector(clickDetector)
                end
            end
        end
    end
end

local function StartCashAura()
    if CashAuraConnection then return end
    
    CashAuraConnection = task.spawn(function()
        while CashAuraEnabled do
            pcall(CollectCash)
            task.wait(0.1)
        end
    end)
end

local function StopCashAura()
    if CashAuraConnection then
        task.cancel(CashAuraConnection)
        CashAuraConnection = nil
    end
end

-- =============================================
-- CASH DROP SYSTEM
-- =============================================
local CashDropConnection

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

local function StartCashDrop()
    if CashDropConnection then return end
    
    CashDropConnection = task.spawn(function()
        while CashDropEnabled do
            DropCash(15000)
            task.wait(1) -- Spam as fast as possible
        end
    end)
end

local function StopCashDrop()
    if CashDropConnection then
        task.cancel(CashDropConnection)
        CashDropConnection = nil
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
    nameLabel.TextSize = ESPTextSize
    nameLabel.TextColor3 = ESPTextColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    -- Create Highlight
    local highlight = Instance.new('Highlight')
    highlight.FillTransparency = 0.75
    highlight.FillColor = ESPColor
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = ESPColor
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
            
            -- Update text settings
            nameLabel.TextSize = ESPTextSize
            nameLabel.TextColor3 = ESPTextColor
            
            highlight.Parent = character
            highlight.Enabled = true
            
            -- Update name with health
            local health = math.floor(humanoid.Health)
            local maxHealth = math.floor(humanoid.MaxHealth)
            nameLabel.Text = ShowNames and string.format('%s [%d/%d]', player.Name, health, maxHealth) or ''
            
            -- Color based on health or custom color
            if UseHealthColor then
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                local color
                if healthPercent > 0.5 then
                    color = Color3.fromRGB(0, 255, 0)
                elseif healthPercent > 0.25 then
                    color = Color3.fromRGB(255, 255, 0)
                else
                    color = Color3.fromRGB(255, 0, 0)
                end
                highlight.OutlineColor = color
                highlight.FillColor = color
            else
                highlight.OutlineColor = ESPColor
                highlight.FillColor = ESPColor
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
-- MONEY ESP SYSTEM
-- =============================================
local MoneyESPConnection

local function ClearMoneyESP()
    for part, highlight in pairs(MoneyESPObjects) do
        if highlight then
            highlight:Destroy()
        end
    end
    MoneyESPObjects = {}
end

local function UpdateMoneyESP()
    if not MoneyESPEnabled then
        ClearMoneyESP()
        return
    end
    
    local droppedItems = Workspace:FindFirstChild('Ignored') and Workspace.Ignored:FindFirstChild('Drop')
    if not droppedItems then return end
    
    -- Remove highlights for money that no longer exists
    for part, highlight in pairs(MoneyESPObjects) do
        if not part or not part.Parent then
            if highlight then highlight:Destroy() end
            MoneyESPObjects[part] = nil
        end
    end
    
    -- Add highlights for new money
    for _, item in pairs(droppedItems:GetChildren()) do
        if item.Name == 'MoneyDrop' and item:IsA('BasePart') then
            if not MoneyESPObjects[item] then
                local highlight = Instance.new('Highlight')
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = item
                MoneyESPObjects[item] = highlight
            end
        end
    end
end

local function StartMoneyESP()
    if MoneyESPConnection then return end
    MoneyESPConnection = RunService.Heartbeat:Connect(function()
        if MoneyESPEnabled then
            pcall(UpdateMoneyESP)
        end
    end)
end

local function StopMoneyESP()
    if MoneyESPConnection then
        MoneyESPConnection:Disconnect()
        MoneyESPConnection = nil
    end
    ClearMoneyESP()
end

-- =============================================
-- CFRAME SPEED SYSTEM (Undetectable)
-- =============================================
local CFrameSpeedConnection
local MovingDirection = Vector3.new(0, 0, 0)

local function GetMovementDirection()
    local hrp = GetHRP()
    local humanoid = GetCharacter() and GetCharacter():FindFirstChildOfClass('Humanoid')
    if not hrp or not humanoid then return Vector3.new(0, 0, 0) end
    
    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        return moveDirection.Unit
    end
    return Vector3.new(0, 0, 0)
end

local function StartCFrameSpeed()
    if CFrameSpeedConnection then return end
    
    CFrameSpeedConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not CFrameSpeedEnabled then return end
        
        local hrp = GetHRP()
        local humanoid = GetCharacter() and GetCharacter():FindFirstChildOfClass('Humanoid')
        if not hrp or not humanoid then return end
        
        local moveDir = GetMovementDirection()
        if moveDir.Magnitude > 0 then
            -- Apply extra movement based on CFrame (looks natural)
            local extraSpeed = (CFrameSpeedValue - 1) * humanoid.WalkSpeed * deltaTime
            local newPos = hrp.Position + (moveDir * extraSpeed)
            hrp.CFrame = CFrame.new(newPos) * CFrame.Angles(hrp.CFrame:ToEulerAnglesXYZ())
        end
    end)
end

local function StopCFrameSpeed()
    if CFrameSpeedConnection then
        CFrameSpeedConnection:Disconnect()
        CFrameSpeedConnection = nil
    end
end

-- =============================================
-- CFRAME FLY SYSTEM
-- =============================================
local CFrameFlyConnection
local FlyKeys = {
    W = false,
    A = false,
    S = false,
    D = false,
    Space = false,
    LeftControl = false
}

local function StartCFrameFly()
    if CFrameFlyConnection then return end
    
    local hrp = GetHRP()
    local humanoid = GetCharacter() and GetCharacter():FindFirstChildOfClass('Humanoid')
    if not hrp or not humanoid then return end
    
    -- Create BodyGyro to stabilize rotation
    FlyBodyGyro = Instance.new('BodyGyro')
    FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyGyro.P = 9e4
    FlyBodyGyro.Parent = hrp
    
    -- Create BodyVelocity for movement
    FlyBodyVelocity = Instance.new('BodyVelocity')
    FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    FlyBodyVelocity.Parent = hrp
    
    -- Disable falling
    humanoid.PlatformStand = true
    
    CFrameFlyConnection = RunService.Heartbeat:Connect(function()
        if not CFrameFlyEnabled then return end
        
        local hrp = GetHRP()
        local camera = Workspace.CurrentCamera
        if not hrp or not camera then return end
        
        -- Update gyro to match camera
        if FlyBodyGyro then
            FlyBodyGyro.CFrame = camera.CFrame
        end
        
        -- Calculate movement direction
        local direction = Vector3.new(0, 0, 0)
        local camCF = camera.CFrame
        
        if FlyKeys.W then
            direction = direction + camCF.LookVector
        end
        if FlyKeys.S then
            direction = direction - camCF.LookVector
        end
        if FlyKeys.A then
            direction = direction - camCF.RightVector
        end
        if FlyKeys.D then
            direction = direction + camCF.RightVector
        end
        if FlyKeys.Space then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if FlyKeys.LeftControl then
            direction = direction - Vector3.new(0, 1, 0)
        end
        
        -- Apply velocity
        if FlyBodyVelocity then
            if direction.Magnitude > 0 then
                FlyBodyVelocity.Velocity = direction.Unit * CFrameFlySpeed
            else
                FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

local function StopCFrameFly()
    if CFrameFlyConnection then
        CFrameFlyConnection:Disconnect()
        CFrameFlyConnection = nil
    end
    
    if FlyBodyGyro then
        FlyBodyGyro:Destroy()
        FlyBodyGyro = nil
    end
    
    if FlyBodyVelocity then
        FlyBodyVelocity:Destroy()
        FlyBodyVelocity = nil
    end
    
    local humanoid = GetCharacter() and GetCharacter():FindFirstChildOfClass('Humanoid')
    if humanoid then
        humanoid.PlatformStand = false
    end
end

-- Fly key detection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not CFrameFlyEnabled then return end
    
    if input.KeyCode == Enum.KeyCode.W then FlyKeys.W = true end
    if input.KeyCode == Enum.KeyCode.A then FlyKeys.A = true end
    if input.KeyCode == Enum.KeyCode.S then FlyKeys.S = true end
    if input.KeyCode == Enum.KeyCode.D then FlyKeys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then FlyKeys.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftControl then FlyKeys.LeftControl = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then FlyKeys.W = false end
    if input.KeyCode == Enum.KeyCode.A then FlyKeys.A = false end
    if input.KeyCode == Enum.KeyCode.S then FlyKeys.S = false end
    if input.KeyCode == Enum.KeyCode.D then FlyKeys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then FlyKeys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftControl then FlyKeys.LeftControl = false end
end)

-- =============================================
-- MAIN TAB UI
-- =============================================
local CashSection = Tabs.Main:AddLeftGroupbox('Cash')

CashSection:AddToggle('CashAura', {
    Text = 'Cash Aura',
    Default = false,
    Tooltip = 'Teleports to nearby cash to collect it',
    Callback = function(Value)
        CashAuraEnabled = Value
        if Value then
            StartCashAura()
        else
            StopCashAura()
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

CashSection:AddToggle('CashDrop', {
    Text = 'Auto Drop $15,000',
    Default = false,
    Tooltip = 'Spams dropping $15,000',
    Callback = function(Value)
        CashDropEnabled = Value
        if Value then
            StartCashDrop()
            Library:Notify('Spamming cash drop!', 2)
        else
            StopCashDrop()
            Library:Notify('Stopped cash drop', 2)
        end
    end
})

-- =============================================
-- MOVEMENT SECTION
-- =============================================
local MovementSection = Tabs.Main:AddRightGroupbox('Movement')

MovementSection:AddToggle('CFrameSpeed', {
    Text = 'CFrame Speed',
    Default = false,
    Tooltip = 'Undetectable speed boost using CFrame',
    Callback = function(Value)
        CFrameSpeedEnabled = Value
        if Value then
            StartCFrameSpeed()
            Library:Notify('CFrame Speed enabled!', 2)
        else
            StopCFrameSpeed()
            Library:Notify('CFrame Speed disabled', 2)
        end
    end
}):AddKeyPicker('CFrameSpeedKey', {
    Default = 'V',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'CFrame Speed',
    NoUI = false
})

MovementSection:AddSlider('SpeedMultiplier', {
    Text = 'Speed Multiplier',
    Default = 1.5,
    Min = 1.1,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Tooltip = '1.5-2x is safest, higher may get detected',
    Callback = function(Value)
        CFrameSpeedValue = Value
    end
})

MovementSection:AddDivider()

MovementSection:AddToggle('CFrameFly', {
    Text = 'CFrame Fly',
    Default = false,
    Tooltip = 'Fly using WASD + Space/Ctrl',
    Callback = function(Value)
        CFrameFlyEnabled = Value
        if Value then
            StartCFrameFly()
            Library:Notify('Flying! WASD to move, Space/Ctrl for up/down', 3)
        else
            StopCFrameFly()
            Library:Notify('Fly disabled', 2)
        end
    end
}):AddKeyPicker('FlyKey', {
    Default = 'F',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Fly',
    NoUI = false
})

MovementSection:AddSlider('FlySpeed', {
    Text = 'Fly Speed',
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Compact = false,
    Tooltip = 'How fast you fly',
    Callback = function(Value)
        CFrameFlySpeed = Value
    end
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

ESPSection:AddToggle('UseHealthColor', {
    Text = 'Health-Based Color',
    Default = true,
    Tooltip = 'Changes ESP color based on player health',
    Callback = function(Value)
        UseHealthColor = Value
    end
})

ESPSection:AddLabel('ESP Color'):AddColorPicker('ESPColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'ESP Color',
    Transparency = 0,
    Callback = function(Value)
        ESPColor = Value
    end
})

ESPSection:AddLabel('Text Color'):AddColorPicker('TextColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Text Color',
    Transparency = 0,
    Callback = function(Value)
        ESPTextColor = Value
    end
})

ESPSection:AddSlider('TextSize', {
    Text = 'Text Size',
    Default = 14,
    Min = 8,
    Max = 24,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        ESPTextSize = Value
    end
})

ESPSection:AddToggle('MoneyESP', {
    Text = 'Money ESP',
    Default = false,
    Tooltip = 'Highlights dropped cash',
    Callback = function(Value)
        MoneyESPEnabled = Value
        if Value then
            StartMoneyESP()
        else
            StopMoneyESP()
        end
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
        CashAuraEnabled = false
        CashDropEnabled = false
        MoneyESPEnabled = false
        CFrameSpeedEnabled = false
        CFrameFlyEnabled = false
        StopCashAura()
        StopCashDrop()
        StopMoneyESP()
        StopCFrameSpeed()
        StopCFrameFly()
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
