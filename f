--[[
    NEBULA HUB v5.9 | Force Metatable Shot Hook
    Features: 
    - Metatable & Network Event Hooking for Instant Shot Power
    - Extended Shot Velocity Slider (Up to 20x Velocity)
    - Zero Player Knockback & Fixed Flat Trajectory
    - Anti-Bot GK Shield (Freezes/Confuses AI Goalkeepers)
    - Direct Module GK Auto Dive & Range Multiplier
    - Unlimited Stamina & Auto Sprint
    - Spin Macro [F]
    - Power Tackle & Slider
    - Extreme Unpredictable Shots (Heavy Knuckleball)
    - Hyper Curve Assist (Mega-Curl on Shots)
    - No-Touch Dribble Assist & Instant Skill Recovery
    - Anti-Auto Dive
    - Goal Area Highlight
    - Camera Max Zoom Slider
    - Config Save/Load
]]

pcall(function() 
    loadstring(game:HttpGet("https://scriptblox.com/ingest/clientv2.lua"))("proj_64f97f78a5b9", "1.0.0", false) 
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local configFileName = "NebulaHub_FootballConfig.json"

local staminaEnabled = false
local tackleEnabled = false
local shotEnabled = false
local autoSprintEnabled = false
local spinMacroEnabled = false
local goalHighlightEnabled = false
local antiAutoDiveEnabled = false
local unpredictableShotsEnabled = false
local dribbleAssistEnabled = false
local skillRecoveryEnabled = false
local hyperCurveEnabled = false
local autoDiveEnabled = false
local antiBotGkEnabled = true

local tackleMultiplier = 1.4
local shotMultiplier = 2.2
local shotVelocityMultiplier = 5.0
local maxZoomDistance = 400

-- Загрузка конфига
pcall(function()
    if isfile and isfile(configFileName) then
        local decoded = HttpService:JSONDecode(readfile(configFileName))
        if decoded then
            staminaEnabled = decoded.Stamina or false
            autoSprintEnabled = decoded.AutoSprint or false
            spinMacroEnabled = decoded.SpinMacro or false
            tackleEnabled = decoded.Tackle or false
            tackleMultiplier = decoded.TackleMult or 1.4
            shotEnabled = decoded.Shot or false
            shotMultiplier = decoded.ShotMult or 2.2
            shotVelocityMultiplier = decoded.ShotVelocityMult or 5.0
            maxZoomDistance = decoded.MaxZoom or 400
            goalHighlightEnabled = decoded.GoalHighlight or false
            antiAutoDiveEnabled = decoded.AntiAutoDive or false
            unpredictableShotsEnabled = decoded.Unpredictable or false
            dribbleAssistEnabled = decoded.DribbleAssist or false
            skillRecoveryEnabled = decoded.SkillRecovery or false
            hyperCurveEnabled = decoded.HyperCurve or false
            autoDiveEnabled = decoded.AutoDive or false
            antiBotGkEnabled = decoded.AntiBotGK or true
        end
    end
end)

pcall(function()
    localPlayer.CameraMaxZoomDistance = maxZoomDistance
end)

local function saveConfig()
    pcall(function()
        local dataToSave = {
            Stamina = staminaEnabled,
            AutoSprint = autoSprintEnabled,
            SpinMacro = spinMacroEnabled,
            Tackle = tackleEnabled,
            TackleMult = tackleMultiplier,
            Shot = shotEnabled,
            ShotMult = shotMultiplier,
            ShotVelocityMult = shotVelocityMultiplier,
            MaxZoom = maxZoomDistance,
            GoalHighlight = goalHighlightEnabled,
            AntiAutoDive = antiAutoDiveEnabled,
            Unpredictable = unpredictableShotsEnabled,
            DribbleAssist = dribbleAssistEnabled,
            SkillRecovery = skillRecoveryEnabled,
            HyperCurve = hyperCurveEnabled,
            AutoDive = autoDiveEnabled,
            AntiBotGK = antiBotGkEnabled
        }
        if writefile then
            writefile(configFileName, HttpService:JSONEncode(dataToSave))
        end
    end)
end

-- 1. ХУК СТАМИНЫ
local sprintDataModule = nil
pcall(function()
    local updateSprint = filtergc("function", {Name = "updateSprint"}, true)
    if updateSprint then
        sprintDataModule = debug.getupvalue(updateSprint, 14)
        if sprintDataModule and sprintDataModule.Update then
            local Update = sprintDataModule.Update
            local oldUpdate
            oldUpdate = hookfunction(Update, function(...)
                local data = select(2, ...)
                if data then
                    if staminaEnabled and rawget(data, "HasUnlimitedStamina") ~= nil then
                        rawset(data, "HasUnlimitedStamina", true)
                    end
                    if autoSprintEnabled then
                        if rawget(data, "IsSprinting") ~= nil then
                            rawset(data, "IsSprinting", true)
                        elseif rawget(data, "Sprinting") ~= nil then
                            rawset(data, "Sprinting", true)
                        end
                    end
                end
                return oldUpdate(...)
            end)
        end
    end
end)

-- 2. ГЛУБОКИЙ ХУК МЕТАТАБЛИЦ И СЕТЕВЫХ СОБЫТИЙ УДАРА (Прямой перехват)
pcall(function()
    local rawMeta = getrawmetatable(game)
    if rawMeta then
        setreadonly(rawMeta, false)
        local oldNamecall = rawMeta.__namecall
        
        rawMeta.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if shotEnabled and (method == "FireServer" or method == "InvokeServer") then
                local name = tostring(self.Name):lower()
                if name:find("shoot") or name:find("shot") or name:find("kick") or name:find("strike") or name:find("action") then
                    for i, arg in ipairs(args) do
                        if type(arg) == "table" then
                            if rawget(arg, "Power") then rawset(arg, "Power", rawget(arg, "Power") * shotMultiplier) end
                            if rawget(arg, "Charge") then rawset(arg, "Charge", rawget(arg, "Charge") * shotMultiplier) end
                            if rawget(arg, "Force") then rawset(arg, "Force", rawget(arg, "Force") * shotMultiplier) end
                            if rawget(arg, "Speed") then rawset(arg, "Speed", rawget(arg, "Speed") * shotVelocityMultiplier) end
                            if rawget(arg, "Elevation") then rawset(arg, "Elevation", 0) end
                            if rawget(arg, "Angle") then rawset(arg, "Angle", 0) end
                        elseif type(arg) == "number" then
                            args[i] = arg * shotMultiplier
                        end
                    end
                end
            end
            return oldNamecall(self, unpack(args))
        end)
        setreadonly(rawMeta, true)
    end
end)

-- Сканирование и постоянная перезапись модулей
local SlideTackleMod = nil
local TackBack = nil
local ActionModules = {}
local ActionBackups = {}
local DribbleModules = {}
local DiveModules = {}
local DiveBackups = {}

pcall(function()
    SlideTackleMod = require(ReplicatedStorage.Modules.Actions.SlideTackle)
    if SlideTackleMod and SlideTackleMod.Constants then
        TackBack = table.clone(SlideTackleMod.Constants)
    end
end)

pcall(function()
    local function scanModules(folder)
        for _, child in pairs(folder:GetChildren()) do
            if child:IsA("ModuleScript") then
                local name = child.Name:lower()
                if name:find("shoot") or name:find("shot") or name:find("kick") or name:find("strike") then
                    pcall(function()
                        local mod = require(child)
                        if mod and (mod.Constants or type(mod) == "table") then
                            table.insert(ActionModules, mod)
                            local targetTable = mod.Constants or mod
                            table.insert(ActionBackups, table.clone(targetTable))
                        end
                    end)
                elseif name:find("dribble") or name:find("skill") or name:find("deke") or name:find("move") then
                    pcall(function()
                        local mod = require(child)
                        if mod then table.insert(DribbleModules, mod) end
                    end)
                elseif name:find("dive") or name:find("save") or name:find("catch") or name:find("keeper") then
                    pcall(function()
                        local mod = require(child)
                        if mod and (mod.Constants or type(mod) == "table") then
                            table.insert(DiveModules, mod)
                            local targetTable = mod.Constants or mod
                            table.insert(DiveBackups, table.clone(targetTable))
                        end
                    end)
                end
            elseif child:IsA("Folder") then
                scanModules(child)
            end
        end
    end

    if ReplicatedStorage:FindFirstChild("Modules") then
        scanModules(ReplicatedStorage.Modules)
    end
end)

local function applyShotPower()
    pcall(function()
        local mult = shotEnabled and shotMultiplier or 1
        for i, mod in ipairs(ActionModules) do
            local targetTable = mod.Constants or mod
            local backup = ActionBackups[i]
            if targetTable and backup then
                for k, v in pairs(backup) do
                    if typeof(v) == "number" then
                        local keyLower = tostring(k):lower()
                        if keyLower:find("power") or keyLower:find("speed") or keyLower:find("force") or keyLower:find("charge") then
                            targetTable[k] = v * mult
                        else
                            targetTable[k] = v
                        end
                    else
                        targetTable[k] = v
                    end
                end
                
                if targetTable.ElevationAngle ~= nil then targetTable.ElevationAngle = 0.05 end
                if targetTable.MaxElevation ~= nil then targetTable.MaxElevation = 0.1 end
                if targetTable.LiftForce ~= nil then targetTable.LiftForce = 0 end
                if targetTable.MaxLift ~= nil then targetTable.MaxLift = 0 end
                
                if targetTable.RecoilForce ~= nil then targetTable.RecoilForce = 0 end
                if targetTable.PlayerKnockback ~= nil then targetTable.PlayerKnockback = 0 end
                if targetTable.Knockback ~= nil then targetTable.Knockback = 0 end
                if targetTable.Recoil ~= nil then targetTable.Recoil = 0 end
                if targetTable.PushBack ~= nil then targetTable.PushBack = 0 end

                if unpredictableShotsEnabled then
                    if targetTable.CurvePower then targetTable.CurvePower = (targetTable.CurvePower or 1) * 3.5 end
                    if targetTable.MinChargeTime then targetTable.MinChargeTime = 0.01 end
                end

                if hyperCurveEnabled then
                    if targetTable.CurvePower then targetTable.CurvePower = (targetTable.CurvePower or 1) * 6.0 end
                    if targetTable.SideForce then targetTable.SideForce = (targetTable.SideForce or 1) * 5.0 end
                end
            end
        end
    end)
end

local function applyDivePower()
    pcall(function()
        for i, mod in ipairs(DiveModules) do
            local targetTable = mod.Constants or mod
            local backup = DiveBackups[i]
            if targetTable and backup then
                for k, v in pairs(backup) do
                    if typeof(v) == "number" then
                        local keyLower = tostring(k):lower()
                        if autoDiveEnabled then
                            if keyLower:find("distance") or keyLower:find("range") or keyLower:find("speed") or keyLower:find("force") then
                                targetTable[k] = v * 2.0
                            elseif keyLower:find("cooldown") or keyLower:find("recovery") or keyLower:find("delay") or keyLower:find("stamina") then
                                targetTable[k] = 0
                            else
                                targetTable[k] = v
                            end
                        else
                            targetTable[k] = v
                        end
                    else
                        targetTable[k] = v
                    end
                end
            end
        end
    end)
end

RunService.Stepped:Connect(function()
    pcall(function()
        if autoSprintEnabled then
            local character = localPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.MoveDirection.Magnitude > 0 and sprintDataModule then
                    if rawget(sprintDataModule, "IsSprinting") ~= nil then
                        rawset(sprintDataModule, "IsSprinting", true)
                    end
                    if rawget(sprintDataModule, "Sprinting") ~= nil then
                        rawset(sprintDataModule, "Sprinting", true)
                    end
                end
            end
        end

        if shotEnabled and localPlayer.Character then
            local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X * 0.5, hrp.AssemblyLinearVelocity.Y, hrp.AssemblyLinearVelocity.Z * 0.5)
            end
        end

        if dribbleAssistEnabled and localPlayer.Character then
            local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in pairs(Workspace:GetChildren()) do
                    if obj.Name:lower():find("ball") or obj.Name:lower():find("football") then
                        if obj:IsA("BasePart") then
                            local dist = (hrp.Position - obj.Position).Magnitude
                            if dist < 8 and dist > 2 then
                                local pullDir = (hrp.Position - obj.Position).Unit
                                obj.AssemblyLinearVelocity = obj.AssemblyLinearVelocity + (pullDir * 4)
                            end
                        end
                    end
                end
            end
        end
    end)
end)

-- Мощный импульс физики мяча (Прямое добавление ускорения)
Workspace.ChildAdded:Connect(function(child)
    if (child.Name:lower():find("ball") or child.Name:lower():find("football")) then
        task.wait(0.01)
        pcall(function()
            if child:IsA("BasePart") then
                local currentVel = child.AssemblyLinearVelocity
                if currentVel.Magnitude > 12 then
                    local camLook = camera.CFrame.LookVector
                    local flatLook = Vector3.new(camLook.X, 0.01, camLook.Z).Unit
                    
                    local boost = (shotEnabled and (shotMultiplier * shotVelocityMultiplier * 25) or 0)
                    local calculatedSpeed = currentVel.Magnitude + boost

                    if shotEnabled then
                        child.AssemblyLinearVelocity = flatLook * calculatedSpeed
                    end

                    if antiBotGkEnabled then
                        task.spawn(function()
                            for i = 1, 5 do
                                task.wait(0.02)
                                if child and child.Parent and child.AssemblyLinearVelocity.Magnitude > 20 then
                                    local microJitter = Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
                                    child.AssemblyLinearVelocity = (flatLook * calculatedSpeed) + microJitter
                                end
                            end
                        end)
                    end

                    if hyperCurveEnabled then
                        task.spawn(function()
                            for i = 1, 8 do
                                task.wait(0.03)
                                if child and child.Parent then
                                    local sideForce = camera.CFrame.RightVector * 28
                                    child.AssemblyLinearVelocity = Vector3.new(child.AssemblyLinearVelocity.X, 0.01, child.AssemblyLinearVelocity.Z) + sideForce
                                end
                            end
                        end)
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    task.wait(1)
    if tackleEnabled then 
        pcall(function()
            if SlideTackleMod and SlideTackleMod.Constants and TackBack then
                for k, v in pairs(TackBack) do
                    if typeof(v) == "number" then
                        if k == "Distance" or k == "StartupDashDistance" or k == "BallKnockSpeed" then
                            SlideTackleMod.Constants[k] = v * tackleMultiplier
                        elseif k == "StaminaCost" then
                            SlideTackleMod.Constants[k] = 0
                        end
                    end
                end
            end
        end)
    end
    if shotEnabled then applyShotPower() end
    if autoDiveEnabled then applyDivePower() end
end)

local function updateGoalHighlight(enabled)
    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Folder") then
                local name = obj.Name:lower()
                if name:find("goal") or name:find("net") or name:find("post") then
                    if enabled then
                        if not obj:FindFirstChild("NebulaGoalHighlight") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "NebulaGoalHighlight"
                            hl.Adornee = obj
                            hl.FillColor = Color3.fromRGB(0, 170, 255)
                            hl.OutlineColor = Color3.fromRGB(138, 43, 226)
                            hl.FillTransparency = 0.6
                            hl.OutlineTransparency = 0.2
                            hl.Parent = obj
                        end
                    else
                        local hl = obj:FindFirstChild("NebulaGoalHighlight")
                        if hl then hl:Destroy() end
                    end
                end
            end
        end
    end)
end

task.spawn(function()
    task.wait(1.5)
    if goalHighlightEnabled then updateGoalHighlight(true) end
end)

local isSpinning = false
local function performSpinTrick()
    if isSpinning then return end
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        isSpinning = true
        local spinTime = 0.15
        local tweenInfo = TweenInfo.new(spinTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

        local targetHrpCFrame = hrp.CFrame * CFrame.Angles(0, math.rad(180), 0)
        local hrpTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetHrpCFrame})

        local cam = Workspace.CurrentCamera
        if cam then
            local camPos = cam.CFrame.Position
            local hrpPos = hrp.Position
            local offset = camPos - hrpPos
            local rotatedOffset = CFrame.Angles(0, math.rad(180), 0) * offset
            local targetCamCFrame = CFrame.new(hrpPos + rotatedOffset, hrpPos + Vector3.new(0, 2, 0))
            
            local camTween = TweenService:Create(cam, tweenInfo, {CFrame = targetCamCFrame})
            camTween:Play()
        end

        hrpTween:Play()
        task.delay(spinTime, function() isSpinning = false end)
    end)
end

UserInputService.InputBegan:Connect(function(input)
    if spinMacroEnabled and input.KeyCode == Enum.KeyCode.F then
        performSpinTrick()
    end
end)

local function applyTacklePower()
    pcall(function()
        if SlideTackleMod and SlideTackleMod.Constants and TackBack then
            local mult = tackleEnabled and tackleMultiplier or 1
            for k, v in pairs(TackBack) do
                if typeof(v) == "number" then
                    if k == "Distance" or k == "StartupDashDistance" or k == "BallKnockSpeed" then
                        SlideTackleMod.Constants[k] = v * tackleMultiplier
                    elseif k == "StaminaCost" and tackleEnabled then
                        SlideTackleMod.Constants[k] = 0
                    else
                        SlideTackleMod.Constants[k] = v
                    end
                else
                    SlideTackleMod.Constants[k] = v
                end
            end
        end
    end)
end

----------------------------------------------------
-- MODERN VERTICAL GUI BUILDER
----------------------------------------------------
if CoreGui:FindFirstChild("NebulaHubGui") then
    CoreGui.NebulaHubGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NebulaHubGui"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 310, 0, 835)
MainFrame.Position = UDim2.new(0.5, -155, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 19)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(138, 43, 226)
MainStroke.Thickness = 1.5

-- Шапка
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
TitleBar.BorderSizePixel = 0

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 12)

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Text = "★ NEBULA HUB <font color='#8A2BE2'>v5.9</font>"
TitleText.RichText = true
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleText.TextSize = 14
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.BackgroundTransparency = 1

local ToggleFrameBtn = Instance.new("TextButton", TitleBar)
ToggleFrameBtn.Size = UDim2.new(0, 28, 0, 28)
ToggleFrameBtn.Position = UDim2.new(1, -38, 0, 8)
ToggleFrameBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
ToggleFrameBtn.Text = "—"
ToggleFrameBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
ToggleFrameBtn.Font = Enum.Font.GothamBold
ToggleFrameBtn.TextSize = 12

local BtnCorner = Instance.new("UICorner", ToggleFrameBtn)
BtnCorner.CornerRadius = UDim.new(0, 6)

-- Скролл контейнер
local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Name = "Container"
Container.Size = UDim2.new(1, -20, 1, -55)
Container.Position = UDim2.new(0, 10, 0, 50)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 3
Container.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
Container.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIList = Instance.new("UIListLayout", Container)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 7)

UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Container.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
end)

local function CreateSectionTitle(title)
    local label = Instance.new("TextLabel", Container)
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = "  " .. title:upper()
    label.TextColor3 = Color3.fromRGB(138, 43, 226)
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
end

local function CreateToggleBtn(text, defaultState, onClick)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = defaultState and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(35, 35, 50)
    stroke.Thickness = 1

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextSize = 11
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left

    local statusBadge = Instance.new("TextButton", frame)
    statusBadge.Size = UDim2.new(0, 50, 0, 22)
    statusBadge.Position = UDim2.new(1, -60, 0.5, -11)
    statusBadge.BackgroundColor3 = defaultState and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(35, 35, 50)
    statusBadge.Text = defaultState and "ON" or "OFF"
    statusBadge.TextColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)
    statusBadge.TextSize = 10
    statusBadge.Font = Enum.Font.GothamBold

    local badgeCorner = Instance.new("UICorner", statusBadge)
    badgeCorner.CornerRadius = UDim.new(0, 6)

    local state = defaultState
    statusBadge.MouseButton1Click:Connect(function()
        state = not state
        statusBadge.Text = state and "ON" or "OFF"
        statusBadge.BackgroundColor3 = state and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(35, 35, 50)
        statusBadge.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)
        stroke.Color = state and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(35, 35, 50)
        onClick(state)
    end)
end

local function CreateSlider(text, min, max, default, isFloat, callback)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(35, 35, 50)
    stroke.Thickness = 1

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextSize = 11
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valLabel = Instance.new("TextLabel", frame)
    valLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valLabel.Position = UDim2.new(0.7, -12, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = isFloat and string.format("%.2f", default) or string.format("%.0f", default)
    valLabel.TextColor3 = Color3.fromRGB(138, 43, 226)
    valLabel.TextSize = 11
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Right

    local sliderBar = Instance.new("TextButton", frame)
    sliderBar.Size = UDim2.new(1, -24, 0, 6)
    sliderBar.Position = UDim2.new(0, 12, 0, 30)
    sliderBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    sliderBar.Text = ""
    sliderBar.AutoButtonColor = false

    local barCorner = Instance.new("UICorner", sliderBar)
    barCorner.CornerRadius = UDim.new(0, 3)

    local fill = Instance.new("Frame", sliderBar)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    fill.BorderSizePixel = 0

    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(0, 3)

    local dragging = false

    local function updateValue(input)
        local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        local val = isFloat and (min + (max - min) * pos) or math.floor(min + (max - min) * pos)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        valLabel.Text = isFloat and string.format("%.2f", val) or string.format("%.0f", val)
        callback(val)
    end

    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateValue(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)
end

----------------------------------------------------
-- ЭЛЕМЕНТЫ ПАНЕЛИ
----------------------------------------------------
CreateSectionTitle("Player & Movement")
CreateToggleBtn("Unlimited Stamina", staminaEnabled, function(enabled)
    staminaEnabled = enabled
end)

CreateToggleBtn("Auto Sprint", autoSprintEnabled, function(enabled)
    autoSprintEnabled = enabled
end)

CreateToggleBtn("Spin Macro [F]", spinMacroEnabled, function(enabled)
    spinMacroEnabled = enabled
end)

CreateSectionTitle("Goalkeeper Modules")
CreateToggleBtn("GK Auto Dive", autoDiveEnabled, function(enabled)
    autoDiveEnabled = enabled
    applyDivePower()
end)

CreateSectionTitle("Combat & Power")
CreateToggleBtn("Power Tackle", tackleEnabled, function(enabled)
    tackleEnabled = enabled
    applyTacklePower()
end)

CreateSlider("Tackle Multiplier", 1.0, 1.8, tackleMultiplier, true, function(val)
    tackleMultiplier = val
    if tackleEnabled then applyTacklePower() end
end)

CreateToggleBtn("Power Shot", shotEnabled, function(enabled)
    shotEnabled = enabled
    applyShotPower()
end)

CreateSlider("Shot Power Multiplier", 1.0, 4.0, shotMultiplier, true, function(val)
    shotMultiplier = val
    if shotEnabled then applyShotPower() end
end)

CreateSlider("Shot Velocity Multiplier", 1.0, 20.0, shotVelocityMultiplier, true, function(val)
    shotVelocityMultiplier = val
end)

CreateSectionTitle("Gameplay & Dribble Assist")
CreateToggleBtn("No-Touch Dribble Assist", dribbleAssistEnabled, function(enabled)
    dribbleAssistEnabled = enabled
end)

CreateToggleBtn("Instant Skill Recovery", skillRecoveryEnabled, function(enabled)
    skillRecoveryEnabled = enabled
    applyShotPower()
end)

CreateSectionTitle("Anti-Keeper Advantages")
CreateToggleBtn("Freeze Bot GK", antiBotGkEnabled, function(enabled)
    antiBotGkEnabled = enabled
    applyShotPower()
end)

CreateToggleBtn("Unpredictable Shots", unpredictableShotsEnabled, function(enabled)
    unpredictableShotsEnabled = enabled
    applyShotPower()
end)

CreateToggleBtn("Hyper Curve Assist", hyperCurveEnabled, function(enabled)
    hyperCurveEnabled = enabled
    applyShotPower()
end)

CreateToggleBtn("Anti-Auto Dive", antiAutoDiveEnabled, function(enabled)
    antiAutoDiveEnabled = enabled
    applyShotPower()
end)

CreateSectionTitle("Visuals & ESP")
CreateToggleBtn("Goal Area Highlight", goalHighlightEnabled, function(enabled)
    goalHighlightEnabled = enabled
    updateGoalHighlight(enabled)
end)

CreateSectionTitle("Camera & View")
CreateSlider("Max Zoom Distance", 50, 1000, maxZoomDistance, false, function(val)
    maxZoomDistance = val
    localPlayer.CameraMaxZoomDistance = val
end)

-- Кнопка сохранения конфигурации
CreateSectionTitle("Configuration")
local saveBtn = Instance.new("TextButton", Container)
saveBtn.Size = UDim2.new(1, 0, 0, 36)
saveBtn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
saveBtn.Text = "SAVE CONFIG"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.TextSize = 12
saveBtn.Font = Enum.Font.GothamBold

local saveCorner = Instance.new("UICorner", saveBtn)
saveCorner.CornerRadius = UDim.new(0, 8)

saveBtn.MouseButton1Click:Connect(function()
    saveConfig()
    saveBtn.Text = "SAVED!"
    task.delay(1, function()
        saveBtn.Text = "SAVE CONFIG"
    end)
end)

-- Сворачивание панели
local isMinimized = false
ToggleFrameBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Container.Visible = not isMinimized
    MainFrame.Size = isMinimized and UDim2.new(0, 310, 0, 45) or UDim2.new(0, 310, 0, 835)
    ToggleFrameBtn.Text = isMinimized and "+" or "—"
end)
