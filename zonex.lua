local teamCheck = false
local fov = 90
local smoothing = 0.1
local predictionFactor = 0.124 -- Adjust this factor to improve prediction accuracy
local highlightEnabled = false -- Variable to enable or disable target highlighting. Change to False if using an ESP script.
local lockPart = "Head" -- Choose what part it locks onto. Ex. HumanoidRootPart or Head

local Toggle = false -- Enable or disable toggle mode
local ToggleKey = Enum.KeyCode.E -- Choose the key for toggling aimbot lock

local useHealthBasedTargeting = false -- Set to true to prioritize health-based targeting
local useDistanceBasedTargeting = false -- Set to true to use distance-based targeting
local maxDistance = 500 -- Maximum targeting distance for distance-based mode

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

StarterGui:SetCore("SendNotification", {
    Title = "universal";
    Text = "king von also approves";
    Icon = "rbxassetid://116467750063870";
    Duration = 5;
})

local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 1
FOVring.Radius = fov
FOVring.Transparency = 0.8
FOVring.Color = Color3.fromRGB(160,32,240)
FOVring.Position = Camera.ViewportSize / 2

local currentTarget = nil
local aimbotEnabled = true
local toggleState = false -- Variable to keep track of toggle state
local debounce = false -- Debounce variable

local function isVisible(target)
    if not target or not target.Character or not target.Character:FindFirstChild(lockPart) then
        return false
    end

    local origin = Camera.CFrame.Position
    local targetPosition = target.Character[lockPart].Position
    local direction = (targetPosition - origin).Unit

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction * (targetPosition - origin).Magnitude, raycastParams)

    return result == nil or result.Instance:IsDescendantOf(target.Character)
end

local function getClosestByDistance()
    local closestTarget = nil
    local closestDistance = math.huge

    for _, v in pairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild(lockPart) and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v ~= Players.LocalPlayer and (v.Team ~= Players.LocalPlayer.Team or (not teamCheck)) then
            local distance = (v.Character[lockPart].Position - Camera.CFrame.Position).Magnitude
            if distance < closestDistance and distance <= maxDistance and isVisible(v) then
                closestDistance = distance
                closestTarget = v
            end
        end
    end

    return closestTarget
end

local function getClosestByHealth()
    local lowestHealthTarget = nil
    local lowestHealth = math.huge

    for _, v in pairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild(lockPart) and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v ~= Players.LocalPlayer and (v.Team ~= Players.LocalPlayer.Team or (not teamCheck)) then
            local health = v.Character.Humanoid.Health
            if health < lowestHealth and health > 0 and isVisible(v) then
                lowestHealth = health
                lowestHealthTarget = v
            end
        end
    end

    return lowestHealthTarget
end

local function getClosestDefault()
    local closestTarget = nil
    local closestMagnitude = math.huge
    local screenCenter = Camera.ViewportSize / 2

    for _, v in pairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild(lockPart) and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v ~= Players.LocalPlayer and (v.Team ~= Players.LocalPlayer.Team or (not teamCheck)) then
            local screenPoint, onScreen = Camera:WorldToViewportPoint(v.Character[lockPart].Position)
            local distanceFromCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude

            if onScreen and distanceFromCenter < closestMagnitude and isVisible(v) then
                closestMagnitude = distanceFromCenter
                closestTarget = v
            end
        end
    end

    return closestTarget
end

local function getClosestTarget()
    if useHealthBasedTargeting then
        local healthTarget = getClosestByHealth()
        if healthTarget then
            return healthTarget
        end
    end
    if useDistanceBasedTargeting then
        local distanceTarget = getClosestByDistance()
        if distanceTarget then
            return distanceTarget
        end
    end
    return getClosestDefault() -- Default targeting if no modes are enabled
end

local function updateFOVRing()
    FOVring.Position = Camera.ViewportSize / 2
end

local function highlightTarget(target)
    if highlightEnabled and target and target.Character then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = target.Character
        highlight.FillColor = Color3.fromRGB(160,32,240)
        highlight.OutlineColor = Color3.fromRGB(160,32,240)
        highlight.Parent = target.Character
    end
end

local function removeHighlight(target)
    if highlightEnabled and target and target.Character and target.Character:FindFirstChildOfClass("Highlight") then
        target.Character:FindFirstChildOfClass("Highlight"):Destroy()
    end
end

local function predictPosition(target)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local velocity = target.Character.HumanoidRootPart.Velocity
        local position = target.Character[lockPart].Position
        local predictedPosition = position + (velocity * predictionFactor)
        return predictedPosition
    end
    return nil
end

local function handleToggle()
    if debounce then return end
    debounce = true
    toggleState = not toggleState
    wait(0.3) -- Debounce time to prevent multiple toggles
    debounce = false
end

loop = RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        updateFOVRing()

        if Toggle then
            if UserInputService:IsKeyDown(ToggleKey) then
                handleToggle()
            end
        else
            toggleState = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end

        if toggleState then
            if not currentTarget or (currentTarget.Character and currentTarget.Character.Humanoid.Health <= 0) then
                if currentTarget and highlightEnabled then
                    removeHighlight(currentTarget)
                end
                currentTarget = getClosestTarget()
                highlightTarget(currentTarget)
            end

            if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild(lockPart) then
                local predictedPosition = predictPosition(currentTarget)
                if predictedPosition then
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPosition), smoothing)
                end
                FOVring.Color = Color3.fromRGB(0, 255, 0) -- Change FOV ring color to green when locked onto a target
            else
                FOVring.Color = Color3.fromRGB(160,32,240) -- Revert FOV ring color to original when not locked onto a target
            end
        else
            if currentTarget and highlightEnabled then
                removeHighlight(currentTarget)
            end
            currentTarget = nil
            FOVring.Color = Color3.fromRGB(160,32,240) -- Revert FOV ring color to original when not locked onto a target
        end
    end
end)

local ESPEnabled = false -- Toggle ESP on or off
local boxColor = Color3.fromRGB(160,32,240) -- Box color

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- Function to create a BillboardGui with a frame for ESP
local function createESP(player)
	if player == localPlayer or (teamCheck and player.Team == localPlayer.Team) then
		return nil
	end

	local character = player.Character
	if not character then return nil end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return nil end

	-- Check if ESP already exists
	if humanoidRootPart:FindFirstChild("ESPBox") then
		return nil
	end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "ESPBox"
	billboardGui.Adornee = humanoidRootPart
	billboardGui.Size = UDim2.new(4, 0, 6, 0) -- Adjust size to fit character
	billboardGui.StudsOffset = Vector3.new(0, 0, 0) -- Position slightly above character
	billboardGui.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0

	-- Outline box
	local outline = Instance.new("UIStroke")
	outline.Thickness = 2
	outline.Color = boxColor
	outline.Parent = frame

	frame.Parent = billboardGui
	billboardGui.Parent = humanoidRootPart
end

-- Function to remove ESP for a player
local function removeESP(player)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart and humanoidRootPart:FindFirstChild("ESPBox") then
		humanoidRootPart:FindFirstChild("ESPBox"):Destroy()
	end
end

-- Function to update ESP for all players
local function updateESP()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if ESPEnabled then
				createESP(player)
			else
				removeESP(player)
			end
		else
			removeESP(player)
		end
	end
end

-- Listen for when players are added
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		if ESPEnabled then
			createESP(player)
		end
	end)
end)

-- Listen for when players are removed
Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
end)

-- Continuously update ESP
RunService.RenderStepped:Connect(function()
	if ESPEnabled then
		updateESP()
	end
end)

local G2L = {};

-- StarterGui.Watermark
G2L["1"] = Instance.new("ScreenGui", game:GetService("CoreGui"));
G2L["1"]["Name"] = [[Watermark]];
G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;


-- StarterGui.Watermark.initial
G2L["2"] = Instance.new("Frame", G2L["1"]);
G2L["2"]["BorderSizePixel"] = 3;
G2L["2"]["BackgroundColor3"] = Color3.fromRGB(80, 80, 80);
G2L["2"]["Size"] = UDim2.new(0.7, 0, 0.02524, 0);
G2L["2"]["Position"] = UDim2.new(0.00773, 0, 0.02782, 0);
G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["2"]["Name"] = [[initial]];
G2L["2"]["BackgroundTransparency"] = 0.45;


-- StarterGui.Watermark.initial.outline
G2L["3"] = Instance.new("Frame", G2L["2"]);
G2L["3"]["BorderSizePixel"] = 0;
G2L["3"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
G2L["3"]["Size"] = UDim2.new(1, 0, -1, 0);
G2L["3"]["Position"] = UDim2.new(-0, 0, 1, 0);
G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["3"]["Name"] = [[outline]];
G2L["3"]["BackgroundTransparency"] = 0.45;


-- StarterGui.Watermark.initial.outline.zonex
G2L["4"] = Instance.new("TextLabel", G2L["3"]);
G2L["4"]["BorderSizePixel"] = 0;
G2L["4"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["4"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["4"]["TextSize"] = 14;
G2L["4"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["4"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["4"]["BackgroundTransparency"] = 1;
G2L["4"]["Size"] = UDim2.new(0.9918, 0, -1, 0);
G2L["4"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4"]["Text"] = [[zonex.lol]];
G2L["4"]["Name"] = [[zonex]];
G2L["4"]["Position"] = UDim2.new(0.01, 0, 1, 0);


-- StarterGui.Watermark.initial.outline.zonex.UIGradient
G2L["5"] = Instance.new("UIGradient", G2L["4"]);
G2L["5"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.initial.outline.zonex.gradient
G2L["6"] = Instance.new("LocalScript", G2L["4"]);
G2L["6"]["Name"] = [[gradient]];


-- StarterGui.Watermark.initial.outline.encourage
G2L["7"] = Instance.new("TextLabel", G2L["3"]);
G2L["7"]["BorderSizePixel"] = 0;
G2L["7"]["TextXAlignment"] = Enum.TextXAlignment.Right;
G2L["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["7"]["TextSize"] = 14;
G2L["7"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["7"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["7"]["BackgroundTransparency"] = 1;
G2L["7"]["Size"] = UDim2.new(0.99, 0, 1, 0);
G2L["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["7"]["Text"] = [[this script was made by fucking zonesafe |]];
G2L["7"]["Name"] = [[encourage]];
G2L["7"]["Position"] = UDim2.new(-0.16896, 0, 0.03581, 0);


-- StarterGui.Watermark.initial.outline.encourage.UIGradient
G2L["8"] = Instance.new("UIGradient", G2L["7"]);
G2L["8"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.initial.outline.time
G2L["9"] = Instance.new("TextLabel", G2L["3"]);
G2L["9"]["BorderSizePixel"] = 0;
G2L["9"]["TextXAlignment"] = Enum.TextXAlignment.Right;
G2L["9"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["9"]["TextSize"] = 14;
G2L["9"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["9"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["9"]["BackgroundTransparency"] = 1;
G2L["9"]["Size"] = UDim2.new(0.9918, 0, -1, 0);
G2L["9"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["9"]["Text"] = [[time]];
G2L["9"]["Name"] = [[time]];
G2L["9"]["Position"] = UDim2.new(-0.05735, 0, 1.03306, 0);


-- StarterGui.Watermark.initial.outline.time.UIGradient
G2L["a"] = Instance.new("UIGradient", G2L["9"]);
G2L["a"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.initial.outline.time.gradient
G2L["b"] = Instance.new("LocalScript", G2L["9"]);
G2L["b"]["Name"] = [[gradient]];


-- StarterGui.Watermark.initial.outline.time.time
G2L["c"] = Instance.new("LocalScript", G2L["9"]);
G2L["c"]["Name"] = [[time]];


-- StarterGui.Watermark.initial.outline.gradient
G2L["d"] = Instance.new("LocalScript", G2L["3"]);
G2L["d"]["Name"] = [[gradient]];


-- StarterGui.Watermark.initial.UIGradient
G2L["e"] = Instance.new("UIGradient", G2L["2"]);
G2L["e"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 255, 255))};


-- StarterGui.Watermark.initial.AmbientShadow
G2L["f"] = Instance.new("ImageLabel", G2L["2"]);
G2L["f"]["ZIndex"] = 0;
G2L["f"]["SliceCenter"] = Rect.new(10, 10, 118, 118);
G2L["f"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["f"]["ImageTransparency"] = 0.8;
G2L["f"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["f"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["f"]["Image"] = [[rbxassetid://1316045217]];
G2L["f"]["Size"] = UDim2.new(1, 5, 1.16968, 5);
G2L["f"]["BackgroundTransparency"] = 1;
G2L["f"]["Name"] = [[AmbientShadow]];
G2L["f"]["Position"] = UDim2.new(0.5, 0, 0.58484, 3);


-- StarterGui.Watermark.initial.PenumbraShadow
G2L["10"] = Instance.new("ImageLabel", G2L["2"]);
G2L["10"]["ZIndex"] = 0;
G2L["10"]["SliceCenter"] = Rect.new(10, 10, 118, 118);
G2L["10"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["10"]["ImageTransparency"] = 0.88;
G2L["10"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["10"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["10"]["Image"] = [[rbxassetid://1316045217]];
G2L["10"]["Size"] = UDim2.new(1, 18, 1, 18);
G2L["10"]["BackgroundTransparency"] = 1;
G2L["10"]["Name"] = [[PenumbraShadow]];
G2L["10"]["Position"] = UDim2.new(0.5, 0, 0.5, 1);


-- StarterGui.Watermark.initial.UmbraShadow
G2L["11"] = Instance.new("ImageLabel", G2L["2"]);
G2L["11"]["ZIndex"] = 0;
G2L["11"]["SliceCenter"] = Rect.new(10, 10, 118, 118);
G2L["11"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["11"]["ImageTransparency"] = 0.86;
G2L["11"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["11"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["11"]["Image"] = [[rbxassetid://1316045217]];
G2L["11"]["Size"] = UDim2.new(1, 10, 1, 10);
G2L["11"]["BackgroundTransparency"] = 1;
G2L["11"]["Name"] = [[UmbraShadow]];
G2L["11"]["Position"] = UDim2.new(0.5, 0, 0.46229, 6);


-- StarterGui.Watermark.initial.drag
G2L["12"] = Instance.new("LocalScript", G2L["2"]);
G2L["12"]["Name"] = [[drag]];


-- StarterGui.Watermark.musica
G2L["13"] = Instance.new("Frame", G2L["1"]);
G2L["13"]["Visible"] = false;
G2L["13"]["BorderSizePixel"] = 0;
G2L["13"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
G2L["13"]["Size"] = UDim2.new(0, 386, 0, 32);
G2L["13"]["Position"] = UDim2.new(0.09698, 0, 0.06954, 0);
G2L["13"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["13"]["Name"] = [[musica]];
G2L["13"]["BackgroundTransparency"] = 0.45;


-- StarterGui.Watermark.musica.UIGradient
G2L["14"] = Instance.new("UIGradient", G2L["13"]);
G2L["14"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 255, 255))};


-- StarterGui.Watermark.musica.AmbientShadow
G2L["15"] = Instance.new("ImageLabel", G2L["13"]);
G2L["15"]["ZIndex"] = 0;
G2L["15"]["SliceCenter"] = Rect.new(10, 10, 118, 118);
G2L["15"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["15"]["ImageTransparency"] = 0.8;
G2L["15"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["15"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["15"]["Image"] = [[rbxassetid://1316045217]];
G2L["15"]["Size"] = UDim2.new(1, 5, 1.16968, 5);
G2L["15"]["BackgroundTransparency"] = 1;
G2L["15"]["Name"] = [[AmbientShadow]];
G2L["15"]["Position"] = UDim2.new(0.5, 0, 0.58484, 3);


-- StarterGui.Watermark.musica.UmbraShadow
G2L["16"] = Instance.new("ImageLabel", G2L["13"]);
G2L["16"]["ZIndex"] = 0;
G2L["16"]["SliceCenter"] = Rect.new(10, 10, 118, 118);
G2L["16"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["16"]["ImageTransparency"] = 0.86;
G2L["16"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["16"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["16"]["Image"] = [[rbxassetid://1316045217]];
G2L["16"]["Size"] = UDim2.new(1, 10, 1, 10);
G2L["16"]["BackgroundTransparency"] = 1;
G2L["16"]["Name"] = [[UmbraShadow]];
G2L["16"]["Position"] = UDim2.new(0.5, 0, 0.46229, 6);


-- StarterGui.Watermark.musica.PenumbraShadow
G2L["17"] = Instance.new("ImageLabel", G2L["13"]);
G2L["17"]["ZIndex"] = 0;
G2L["17"]["SliceCenter"] = Rect.new(10, 10, 118, 118);
G2L["17"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["17"]["ImageTransparency"] = 0.88;
G2L["17"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["17"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["17"]["Image"] = [[rbxassetid://1316045217]];
G2L["17"]["Size"] = UDim2.new(1, 18, 1, 18);
G2L["17"]["BackgroundTransparency"] = 1;
G2L["17"]["Name"] = [[PenumbraShadow]];
G2L["17"]["Position"] = UDim2.new(0.5, 0, 0.5, 1);


-- StarterGui.Watermark.musica.drag
G2L["18"] = Instance.new("LocalScript", G2L["13"]);
G2L["18"]["Name"] = [[drag]];


-- StarterGui.Watermark.musica.play
G2L["19"] = Instance.new("ImageButton", G2L["13"]);
G2L["19"]["BorderSizePixel"] = 0;
G2L["19"]["BackgroundColor3"] = Color3.fromRGB(213, 0, 255);
G2L["19"]["ImageColor3"] = Color3.fromRGB(161, 33, 241);
G2L["19"]["Image"] = [[rbxassetid://12099513379]];
G2L["19"]["Size"] = UDim2.new(0.07, 0, 0.9, 0);
G2L["19"]["BackgroundTransparency"] = 1;
G2L["19"]["Name"] = [[play]];
G2L["19"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["19"]["Position"] = UDim2.new(0.47405, 0, 0.03009, 0);


-- StarterGui.Watermark.musica.UICorner
G2L["1a"] = Instance.new("UICorner", G2L["13"]);



-- StarterGui.Watermark.musica.skip
G2L["1b"] = Instance.new("ImageButton", G2L["13"]);
G2L["1b"]["BorderSizePixel"] = 0;
G2L["1b"]["BackgroundColor3"] = Color3.fromRGB(213, 0, 255);
G2L["1b"]["ImageColor3"] = Color3.fromRGB(161, 33, 241);
G2L["1b"]["Image"] = [[rbxassetid://4458877936]];
G2L["1b"]["Size"] = UDim2.new(0.07, 0, 0.9, 0);
G2L["1b"]["BackgroundTransparency"] = 1;
G2L["1b"]["Name"] = [[skip]];
G2L["1b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["1b"]["Position"] = UDim2.new(0.84452, 0, 0.07823, 0);


-- StarterGui.Watermark.musica.skipback
G2L["1c"] = Instance.new("ImageButton", G2L["13"]);
G2L["1c"]["BorderSizePixel"] = 0;
G2L["1c"]["BackgroundColor3"] = Color3.fromRGB(213, 0, 255);
G2L["1c"]["ImageColor3"] = Color3.fromRGB(161, 33, 241);
G2L["1c"]["LayoutOrder"] = 1;
G2L["1c"]["Image"] = [[rbxassetid://4458877936]];
G2L["1c"]["Size"] = UDim2.new(0.07, 0, 0.9, 0);
G2L["1c"]["BackgroundTransparency"] = 1;
G2L["1c"]["Name"] = [[skipback]];
G2L["1c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["1c"]["Rotation"] = 180;
G2L["1c"]["Position"] = UDim2.new(0.06991, 0, 0.07823, 0);


-- StarterGui.Watermark.musica.UIStroke
G2L["1d"] = Instance.new("UIStroke", G2L["13"]);
G2L["1d"]["Transparency"] = 0.4;
G2L["1d"]["Thickness"] = 3;


-- StarterGui.Watermark.musica.encourage
G2L["1e"] = Instance.new("TextLabel", G2L["13"]);
G2L["1e"]["TextStrokeTransparency"] = 0;
G2L["1e"]["BorderSizePixel"] = 0;
G2L["1e"]["TextXAlignment"] = Enum.TextXAlignment.Right;
G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["1e"]["TextSize"] = 14;
G2L["1e"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["1e"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["1e"]["BackgroundTransparency"] = 1;
G2L["1e"]["Size"] = UDim2.new(0.42471, 0, 1, 0);
G2L["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["1e"]["Text"] = [[Currently playing: Nothing]];
G2L["1e"]["Name"] = [[encourage]];
G2L["1e"]["Position"] = UDim2.new(0.28752, 0, 0.98176, 0);


-- StarterGui.Watermark.musica.encourage.UIGradient
G2L["1f"] = Instance.new("UIGradient", G2L["1e"]);
G2L["1f"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.pressv
G2L["20"] = Instance.new("LocalScript", G2L["1"]);
G2L["20"]["Name"] = [[pressv]];


-- StarterGui.Watermark.fresh
G2L["21"] = Instance.new("Frame", G2L["1"]);
G2L["21"]["BorderSizePixel"] = 3;
G2L["21"]["BackgroundColor3"] = Color3.fromRGB(80, 80, 80);
G2L["21"]["Size"] = UDim2.new(0.7, 0, 0.51834, 0);
G2L["21"]["Position"] = UDim2.new(0.008, 0, 0.0669, 0);
G2L["21"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["21"]["Name"] = [[fresh]];
G2L["21"]["BackgroundTransparency"] = 0.45;


-- StarterGui.Watermark.fresh.UIGradient
G2L["22"] = Instance.new("UIGradient", G2L["21"]);
G2L["22"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 255, 255))};


-- StarterGui.Watermark.fresh.AmbientShadow
G2L["23"] = Instance.new("ImageLabel", G2L["21"]);
G2L["23"]["ZIndex"] = 0;
G2L["23"]["SliceCenter"] = Rect.new(10, 10, 118, 118);
G2L["23"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["23"]["ImageTransparency"] = 0.8;
G2L["23"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["23"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["23"]["Image"] = [[rbxassetid://1316045217]];
G2L["23"]["Size"] = UDim2.new(1, 3, 1, 0);
G2L["23"]["BackgroundTransparency"] = 1;
G2L["23"]["Name"] = [[AmbientShadow]];
G2L["23"]["Position"] = UDim2.new(0.5, 0, 0.52111, 3);


-- StarterGui.Watermark.fresh.PenumbraShadow
G2L["24"] = Instance.new("ImageLabel", G2L["21"]);
G2L["24"]["ZIndex"] = 0;
G2L["24"]["SliceCenter"] = Rect.new(10, 10, 118, 118);
G2L["24"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["24"]["ImageTransparency"] = 0.88;
G2L["24"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["24"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["24"]["Image"] = [[rbxassetid://1316045217]];
G2L["24"]["Size"] = UDim2.new(1, 18, 1, 18);
G2L["24"]["BackgroundTransparency"] = 1;
G2L["24"]["Name"] = [[PenumbraShadow]];
G2L["24"]["Position"] = UDim2.new(0.5, 0, 0.5, 1);


-- StarterGui.Watermark.fresh.UmbraShadow
G2L["25"] = Instance.new("ImageLabel", G2L["21"]);
G2L["25"]["ZIndex"] = 0;
G2L["25"]["SliceCenter"] = Rect.new(10, 10, 118, 118);
G2L["25"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["25"]["ImageTransparency"] = 0.86;
G2L["25"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["25"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["25"]["Image"] = [[rbxassetid://1316045217]];
G2L["25"]["Size"] = UDim2.new(1, 10, 1, 10);
G2L["25"]["BackgroundTransparency"] = 1;
G2L["25"]["Name"] = [[UmbraShadow]];
G2L["25"]["Position"] = UDim2.new(0.5, 0, 0.46229, 6);


-- StarterGui.Watermark.fresh.drag
G2L["26"] = Instance.new("LocalScript", G2L["21"]);
G2L["26"]["Name"] = [[drag]];


-- StarterGui.Watermark.fresh.outline
G2L["27"] = Instance.new("Frame", G2L["21"]);
G2L["27"]["BorderSizePixel"] = 0;
G2L["27"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
G2L["27"]["Size"] = UDim2.new(1, 0, -1, 0);
G2L["27"]["Position"] = UDim2.new(-0, 0, 0.99665, 0);
G2L["27"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["27"]["Name"] = [[outline]];
G2L["27"]["BackgroundTransparency"] = 0.45;


-- StarterGui.Watermark.fresh.tabline
G2L["28"] = Instance.new("Frame", G2L["21"]);
G2L["28"]["BorderSizePixel"] = 0;
G2L["28"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
G2L["28"]["Size"] = UDim2.new(0.01, 0, 1, 0);
G2L["28"]["Position"] = UDim2.new(0.17126, 0, 0.0005, 0);
G2L["28"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["28"]["Name"] = [[tabline]];
G2L["28"]["BackgroundTransparency"] = 0.8;


-- StarterGui.Watermark.fresh.Misc
G2L["29"] = Instance.new("Frame", G2L["21"]);
G2L["29"]["Visible"] = false;
G2L["29"]["ZIndex"] = 2;
G2L["29"]["BorderSizePixel"] = 0;
G2L["29"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["29"]["Size"] = UDim2.new(0.78448, 0, 0.99901, 0);
G2L["29"]["Position"] = UDim2.new(0.1982, 0, 0.03118, 0);
G2L["29"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["29"]["Name"] = [[Misc]];
G2L["29"]["BackgroundTransparency"] = 1;


-- StarterGui.Watermark.fresh.Misc.highlight
G2L["2a"] = Instance.new("TextButton", G2L["29"]);
G2L["2a"]["BorderSizePixel"] = 0;
G2L["2a"]["TextSize"] = 14;
G2L["2a"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
G2L["2a"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
G2L["2a"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["2a"]["Size"] = UDim2.new(0.03653, 0, 0.06, 0);
G2L["2a"]["BackgroundTransparency"] = 0.6;
G2L["2a"]["Name"] = [[highlight]];
G2L["2a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["2a"]["Text"] = [[]];
G2L["2a"]["Position"] = UDim2.new(0.03079, 0, 0.2113, 0);


-- StarterGui.Watermark.fresh.Misc.highlight.UICorner
G2L["2b"] = Instance.new("UICorner", G2L["2a"]);



-- StarterGui.Watermark.fresh.Misc.highlight.highlight
G2L["2c"] = Instance.new("LocalScript", G2L["2a"]);
G2L["2c"]["Name"] = [[highlight]];


-- StarterGui.Watermark.fresh.Misc.highlight.click
G2L["2d"] = Instance.new("LocalScript", G2L["2a"]);
G2L["2d"]["Name"] = [[click]];


-- StarterGui.Watermark.fresh.Misc.highlight.UIStroke
G2L["2e"] = Instance.new("UIStroke", G2L["2a"]);
G2L["2e"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["2e"]["Thickness"] = 1.2;
G2L["2e"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Misc.circle
G2L["2f"] = Instance.new("TextButton", G2L["29"]);
G2L["2f"]["BorderSizePixel"] = 0;
G2L["2f"]["TextSize"] = 14;
G2L["2f"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
G2L["2f"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
G2L["2f"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["2f"]["Size"] = UDim2.new(0.03653, 0, 0.06, 0);
G2L["2f"]["BackgroundTransparency"] = 0.6;
G2L["2f"]["Name"] = [[circle]];
G2L["2f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["2f"]["Text"] = [[]];
G2L["2f"]["Position"] = UDim2.new(0.03079, 0, 0.1241, 0);


-- StarterGui.Watermark.fresh.Misc.circle.UICorner
G2L["30"] = Instance.new("UICorner", G2L["2f"]);



-- StarterGui.Watermark.fresh.Misc.circle.ring
G2L["31"] = Instance.new("LocalScript", G2L["2f"]);
G2L["31"]["Name"] = [[ring]];


-- StarterGui.Watermark.fresh.Misc.circle.click
G2L["32"] = Instance.new("LocalScript", G2L["2f"]);
G2L["32"]["Name"] = [[click]];


-- StarterGui.Watermark.fresh.Misc.circle.UIStroke
G2L["33"] = Instance.new("UIStroke", G2L["2f"]);
G2L["33"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["33"]["Thickness"] = 1.2;
G2L["33"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Misc.team
G2L["34"] = Instance.new("TextButton", G2L["29"]);
G2L["34"]["BorderSizePixel"] = 0;
G2L["34"]["TextSize"] = 14;
G2L["34"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
G2L["34"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
G2L["34"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["34"]["Size"] = UDim2.new(0.03653, 0, 0.06, 0);
G2L["34"]["BackgroundTransparency"] = 0.6;
G2L["34"]["Name"] = [[team]];
G2L["34"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["34"]["Text"] = [[]];
G2L["34"]["Position"] = UDim2.new(0.03079, 0, 0.04025, 0);


-- StarterGui.Watermark.fresh.Misc.team.UICorner
G2L["35"] = Instance.new("UICorner", G2L["34"]);



-- StarterGui.Watermark.fresh.Misc.team.LocalScript
G2L["36"] = Instance.new("LocalScript", G2L["34"]);



-- StarterGui.Watermark.fresh.Misc.team.click
G2L["37"] = Instance.new("LocalScript", G2L["34"]);
G2L["37"]["Name"] = [[click]];


-- StarterGui.Watermark.fresh.Misc.team.UIStroke
G2L["38"] = Instance.new("UIStroke", G2L["34"]);
G2L["38"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["38"]["Thickness"] = 1.2;
G2L["38"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Misc.fovtext
G2L["39"] = Instance.new("TextLabel", G2L["29"]);
G2L["39"]["BorderSizePixel"] = 0;
G2L["39"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["39"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["39"]["TextSize"] = 14;
G2L["39"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["39"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["39"]["BackgroundTransparency"] = 1;
G2L["39"]["Size"] = UDim2.new(0.1509, 0, -0.10112, 0);
G2L["39"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["39"]["Text"] = [[fov circle]];
G2L["39"]["Name"] = [[fovtext]];
G2L["39"]["Position"] = UDim2.new(0.0812, 0, 0.20845, 0);


-- StarterGui.Watermark.fresh.Misc.fovtext.UIGradient
G2L["3a"] = Instance.new("UIGradient", G2L["39"]);
G2L["3a"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Misc.fovtext.gradient
G2L["3b"] = Instance.new("LocalScript", G2L["39"]);
G2L["3b"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Misc.teamtext
G2L["3c"] = Instance.new("TextLabel", G2L["29"]);
G2L["3c"]["BorderSizePixel"] = 0;
G2L["3c"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["3c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["3c"]["TextSize"] = 14;
G2L["3c"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["3c"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["3c"]["BackgroundTransparency"] = 1;
G2L["3c"]["Size"] = UDim2.new(0.1509, 0, -0.10112, 0);
G2L["3c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["3c"]["Text"] = [[team toggle]];
G2L["3c"]["Name"] = [[teamtext]];
G2L["3c"]["Position"] = UDim2.new(0.0812, 0, 0.12124, 0);


-- StarterGui.Watermark.fresh.Misc.teamtext.UIGradient
G2L["3d"] = Instance.new("UIGradient", G2L["3c"]);
G2L["3d"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Misc.teamtext.gradient
G2L["3e"] = Instance.new("LocalScript", G2L["3c"]);
G2L["3e"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Misc.highlightTEXT
G2L["3f"] = Instance.new("TextLabel", G2L["29"]);
G2L["3f"]["BorderSizePixel"] = 0;
G2L["3f"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["3f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["3f"]["TextSize"] = 14;
G2L["3f"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["3f"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["3f"]["BackgroundTransparency"] = 1;
G2L["3f"]["Size"] = UDim2.new(0.1509, 0, -0.10112, 0);
G2L["3f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["3f"]["Text"] = [[highlight]];
G2L["3f"]["Name"] = [[highlightTEXT]];
G2L["3f"]["Position"] = UDim2.new(0.0812, 0, 0.28894, 0);


-- StarterGui.Watermark.fresh.Misc.highlightTEXT.UIGradient
G2L["40"] = Instance.new("UIGradient", G2L["3f"]);
G2L["40"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Misc.highlightTEXT.gradient
G2L["41"] = Instance.new("LocalScript", G2L["3f"]);
G2L["41"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Misc.ImageLabel
G2L["42"] = Instance.new("ImageLabel", G2L["29"]);
G2L["42"]["ZIndex"] = 0;
G2L["42"]["BorderSizePixel"] = 0;
G2L["42"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["42"]["ImageTransparency"] = 0.82;
G2L["42"]["ImageColor3"] = Color3.fromRGB(163, 0, 255);
G2L["42"]["Image"] = [[rbxassetid://12928552195]];
G2L["42"]["Size"] = UDim2.new(0.99756, 0, 0.94634, 0);
G2L["42"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["42"]["BackgroundTransparency"] = 1;
G2L["42"]["Position"] = UDim2.new(0, 0, -0.01007, 0);


-- StarterGui.Watermark.fresh.Misc.esp
G2L["43"] = Instance.new("TextButton", G2L["29"]);
G2L["43"]["BorderSizePixel"] = 0;
G2L["43"]["TextSize"] = 14;
G2L["43"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
G2L["43"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
G2L["43"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["43"]["Size"] = UDim2.new(0.03653, 0, 0.06, 0);
G2L["43"]["BackgroundTransparency"] = 0.6;
G2L["43"]["Name"] = [[esp]];
G2L["43"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["43"]["Text"] = [[]];
G2L["43"]["Position"] = UDim2.new(0.03079, 0, 0.28861, 0);


-- StarterGui.Watermark.fresh.Misc.esp.UICorner
G2L["44"] = Instance.new("UICorner", G2L["43"]);



-- StarterGui.Watermark.fresh.Misc.esp.ring
G2L["45"] = Instance.new("LocalScript", G2L["43"]);
G2L["45"]["Name"] = [[ring]];


-- StarterGui.Watermark.fresh.Misc.esp.click
G2L["46"] = Instance.new("LocalScript", G2L["43"]);
G2L["46"]["Name"] = [[click]];


-- StarterGui.Watermark.fresh.Misc.esp.UIStroke
G2L["47"] = Instance.new("UIStroke", G2L["43"]);
G2L["47"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["47"]["Thickness"] = 1.2;
G2L["47"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Misc.fovtext
G2L["48"] = Instance.new("TextLabel", G2L["29"]);
G2L["48"]["BorderSizePixel"] = 0;
G2L["48"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["48"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["48"]["TextSize"] = 14;
G2L["48"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["48"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["48"]["BackgroundTransparency"] = 1;
G2L["48"]["Size"] = UDim2.new(0.1509, 0, -0.10112, 0);
G2L["48"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["48"]["Text"] = [[esp toggle]];
G2L["48"]["Name"] = [[fovtext]];
G2L["48"]["Position"] = UDim2.new(0.0812, 0, 0.3696, 0);


-- StarterGui.Watermark.fresh.Misc.fovtext.UIGradient
G2L["49"] = Instance.new("UIGradient", G2L["48"]);
G2L["49"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Misc.fovtext.gradient
G2L["4a"] = Instance.new("LocalScript", G2L["48"]);
G2L["4a"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Combat
G2L["4b"] = Instance.new("TextButton", G2L["21"]);
G2L["4b"]["TextWrapped"] = true;
G2L["4b"]["BorderSizePixel"] = 0;
G2L["4b"]["TextSize"] = 14;
G2L["4b"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["4b"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4b"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["4b"]["Size"] = UDim2.new(0.17126, 0, 0.06211, 0);
G2L["4b"]["BackgroundTransparency"] = 0.8;
G2L["4b"]["Name"] = [[Combat]];
G2L["4b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4b"]["Text"] = [[Combat]];
G2L["4b"]["Position"] = UDim2.new(0, 0, 0.03118, 0);


-- StarterGui.Watermark.fresh.Combat.LocalScript
G2L["4c"] = Instance.new("LocalScript", G2L["4b"]);



-- StarterGui.Watermark.fresh.Visuals
G2L["4d"] = Instance.new("TextButton", G2L["21"]);
G2L["4d"]["TextWrapped"] = true;
G2L["4d"]["BorderSizePixel"] = 0;
G2L["4d"]["TextSize"] = 14;
G2L["4d"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["4d"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4d"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["4d"]["Size"] = UDim2.new(0.17126, 0, 0.06211, 0);
G2L["4d"]["BackgroundTransparency"] = 0.8;
G2L["4d"]["Name"] = [[Visuals]];
G2L["4d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4d"]["Text"] = [[Visuals]];
G2L["4d"]["Position"] = UDim2.new(0, 0, 0.11838, 0);


-- StarterGui.Watermark.fresh.Visuals.LocalScript
G2L["4e"] = Instance.new("LocalScript", G2L["4d"]);



-- StarterGui.Watermark.fresh.Aimbot
G2L["4f"] = Instance.new("Frame", G2L["21"]);
G2L["4f"]["ZIndex"] = 2;
G2L["4f"]["BorderSizePixel"] = 0;
G2L["4f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["4f"]["Size"] = UDim2.new(0.78448, 0, 0.99901, 0);
G2L["4f"]["Position"] = UDim2.new(0.1982, 0, 0.03118, 0);
G2L["4f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4f"]["Name"] = [[Aimbot]];
G2L["4f"]["BackgroundTransparency"] = 1;


-- StarterGui.Watermark.fresh.Aimbot.ImageLabel
G2L["50"] = Instance.new("ImageLabel", G2L["4f"]);
G2L["50"]["ZIndex"] = 0;
G2L["50"]["BorderSizePixel"] = 0;
G2L["50"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["50"]["ImageTransparency"] = 0.82;
G2L["50"]["ImageColor3"] = Color3.fromRGB(163, 0, 255);
G2L["50"]["Image"] = [[rbxassetid://12928552195]];
G2L["50"]["Size"] = UDim2.new(0.99756, 0, 0.94634, 0);
G2L["50"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["50"]["BackgroundTransparency"] = 1;
G2L["50"]["Position"] = UDim2.new(0, 0, -0.01007, 0);


-- StarterGui.Watermark.fresh.Aimbot.fov
G2L["51"] = Instance.new("TextBox", G2L["4f"]);
G2L["51"]["CursorPosition"] = -1;
G2L["51"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["51"]["BorderSizePixel"] = 0;
G2L["51"]["TextWrapped"] = true;
G2L["51"]["TextSize"] = 14;
G2L["51"]["Name"] = [[fov]];
G2L["51"]["TextScaled"] = true;
G2L["51"]["BackgroundColor3"] = Color3.fromRGB(53, 53, 53);
G2L["51"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["51"]["Size"] = UDim2.new(0.22618, 0, 0.0929, 0);
G2L["51"]["Position"] = UDim2.new(0.08196, 0, 0.02635, 0);
G2L["51"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["51"]["Text"] = [[fov]];
G2L["51"]["BackgroundTransparency"] = 0.6;


-- StarterGui.Watermark.fresh.Aimbot.fov.LocalScript
G2L["52"] = Instance.new("LocalScript", G2L["51"]);



-- StarterGui.Watermark.fresh.Aimbot.fov.UICorner
G2L["53"] = Instance.new("UICorner", G2L["51"]);
G2L["53"]["CornerRadius"] = UDim.new(0.2, 0);


-- StarterGui.Watermark.fresh.Aimbot.fov.UIStroke
G2L["54"] = Instance.new("UIStroke", G2L["51"]);
G2L["54"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["54"]["Thickness"] = 1.2;
G2L["54"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Aimbot.prediction
G2L["55"] = Instance.new("TextBox", G2L["4f"]);
G2L["55"]["CursorPosition"] = -1;
G2L["55"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["55"]["BorderSizePixel"] = 0;
G2L["55"]["TextWrapped"] = true;
G2L["55"]["TextSize"] = 14;
G2L["55"]["Name"] = [[prediction]];
G2L["55"]["TextScaled"] = true;
G2L["55"]["BackgroundColor3"] = Color3.fromRGB(53, 53, 53);
G2L["55"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["55"]["Size"] = UDim2.new(0.22618, 0, 0.09333, 0);
G2L["55"]["Position"] = UDim2.new(0.08196, 0, 0.32851, 0);
G2L["55"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["55"]["Text"] = [[prediction factor]];
G2L["55"]["BackgroundTransparency"] = 0.6;


-- StarterGui.Watermark.fresh.Aimbot.prediction.LocalScript
G2L["56"] = Instance.new("LocalScript", G2L["55"]);



-- StarterGui.Watermark.fresh.Aimbot.prediction.UICorner
G2L["57"] = Instance.new("UICorner", G2L["55"]);
G2L["57"]["CornerRadius"] = UDim.new(0.2, 0);


-- StarterGui.Watermark.fresh.Aimbot.prediction.UIStroke
G2L["58"] = Instance.new("UIStroke", G2L["55"]);
G2L["58"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["58"]["Thickness"] = 1.2;
G2L["58"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Aimbot.smoothness
G2L["59"] = Instance.new("TextBox", G2L["4f"]);
G2L["59"]["CursorPosition"] = -1;
G2L["59"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["59"]["BorderSizePixel"] = 0;
G2L["59"]["TextWrapped"] = true;
G2L["59"]["TextSize"] = 14;
G2L["59"]["Name"] = [[smoothness]];
G2L["59"]["TextScaled"] = true;
G2L["59"]["BackgroundColor3"] = Color3.fromRGB(53, 53, 53);
G2L["59"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["59"]["Size"] = UDim2.new(0.22618, 0, 0.10004, 0);
G2L["59"]["Position"] = UDim2.new(0.08196, 0, 0.17743, 0);
G2L["59"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["59"]["Text"] = [[smoothness]];
G2L["59"]["BackgroundTransparency"] = 0.6;


-- StarterGui.Watermark.fresh.Aimbot.smoothness.LocalScript
G2L["5a"] = Instance.new("LocalScript", G2L["59"]);



-- StarterGui.Watermark.fresh.Aimbot.smoothness.UICorner
G2L["5b"] = Instance.new("UICorner", G2L["59"]);
G2L["5b"]["CornerRadius"] = UDim.new(0.2, 0);


-- StarterGui.Watermark.fresh.Aimbot.smoothness.UIStroke
G2L["5c"] = Instance.new("UIStroke", G2L["59"]);
G2L["5c"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["5c"]["Thickness"] = 1.2;
G2L["5c"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Aimbot.togle
G2L["5d"] = Instance.new("TextButton", G2L["4f"]);
G2L["5d"]["BorderSizePixel"] = 0;
G2L["5d"]["TextSize"] = 14;
G2L["5d"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
G2L["5d"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
G2L["5d"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["5d"]["Size"] = UDim2.new(0.04859, 0, 0.09022, 0);
G2L["5d"]["BackgroundTransparency"] = 0.6;
G2L["5d"]["Name"] = [[togle]];
G2L["5d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["5d"]["Text"] = [[]];
G2L["5d"]["Position"] = UDim2.new(0.08076, 0, 0.45312, 0);


-- StarterGui.Watermark.fresh.Aimbot.togle.UICorner
G2L["5e"] = Instance.new("UICorner", G2L["5d"]);



-- StarterGui.Watermark.fresh.Aimbot.togle.ring
G2L["5f"] = Instance.new("LocalScript", G2L["5d"]);
G2L["5f"]["Name"] = [[ring]];


-- StarterGui.Watermark.fresh.Aimbot.togle.click
G2L["60"] = Instance.new("LocalScript", G2L["5d"]);
G2L["60"]["Name"] = [[click]];


-- StarterGui.Watermark.fresh.Aimbot.togle.UIStroke
G2L["61"] = Instance.new("UIStroke", G2L["5d"]);
G2L["61"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["61"]["Thickness"] = 1.2;
G2L["61"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Aimbot.toggledd
G2L["62"] = Instance.new("TextLabel", G2L["4f"]);
G2L["62"]["BorderSizePixel"] = 0;
G2L["62"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["62"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["62"]["TextSize"] = 14;
G2L["62"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["62"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["62"]["BackgroundTransparency"] = 1;
G2L["62"]["Size"] = UDim2.new(0.1509, 0, -0.10112, 0);
G2L["62"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["62"]["Text"] = [[Toggleable]];
G2L["62"]["Name"] = [[toggledd]];
G2L["62"]["Position"] = UDim2.new(0.14495, 0, 0.5509, 0);


-- StarterGui.Watermark.fresh.Aimbot.toggledd.UIGradient
G2L["63"] = Instance.new("UIGradient", G2L["62"]);
G2L["63"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Aimbot.toggledd.gradient
G2L["64"] = Instance.new("LocalScript", G2L["62"]);
G2L["64"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Aimbot.disable
G2L["65"] = Instance.new("TextButton", G2L["4f"]);
G2L["65"]["BorderSizePixel"] = 0;
G2L["65"]["TextSize"] = 14;
G2L["65"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
G2L["65"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
G2L["65"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["65"]["Size"] = UDim2.new(0.04859, 0, 0.09022, 0);
G2L["65"]["BackgroundTransparency"] = 0.6;
G2L["65"]["Name"] = [[disable]];
G2L["65"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["65"]["Text"] = [[]];
G2L["65"]["Position"] = UDim2.new(0.08076, 0, 0.57399, 0);


-- StarterGui.Watermark.fresh.Aimbot.disable.UICorner
G2L["66"] = Instance.new("UICorner", G2L["65"]);



-- StarterGui.Watermark.fresh.Aimbot.disable.ring
G2L["67"] = Instance.new("LocalScript", G2L["65"]);
G2L["67"]["Name"] = [[ring]];


-- StarterGui.Watermark.fresh.Aimbot.disable.click
G2L["68"] = Instance.new("LocalScript", G2L["65"]);
G2L["68"]["Name"] = [[click]];


-- StarterGui.Watermark.fresh.Aimbot.disable.UIStroke
G2L["69"] = Instance.new("UIStroke", G2L["65"]);
G2L["69"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["69"]["Thickness"] = 1.2;
G2L["69"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Aimbot.disable
G2L["6a"] = Instance.new("TextLabel", G2L["4f"]);
G2L["6a"]["BorderSizePixel"] = 0;
G2L["6a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["6a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["6a"]["TextSize"] = 14;
G2L["6a"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["6a"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["6a"]["BackgroundTransparency"] = 1;
G2L["6a"]["Size"] = UDim2.new(0.1509, 0, -0.10112, 0);
G2L["6a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["6a"]["Text"] = [[Disabled]];
G2L["6a"]["Name"] = [[disable]];
G2L["6a"]["Position"] = UDim2.new(0.14495, 0, 0.67176, 0);


-- StarterGui.Watermark.fresh.Aimbot.disable.UIGradient
G2L["6b"] = Instance.new("UIGradient", G2L["6a"]);
G2L["6b"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Aimbot.disable.gradient
G2L["6c"] = Instance.new("LocalScript", G2L["6a"]);
G2L["6c"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Aimbot.fovtext
G2L["6d"] = Instance.new("TextLabel", G2L["4f"]);
G2L["6d"]["BorderSizePixel"] = 0;
G2L["6d"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["6d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["6d"]["TextSize"] = 14;
G2L["6d"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["6d"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["6d"]["BackgroundTransparency"] = 1;
G2L["6d"]["Size"] = UDim2.new(0.23878, 0, -0.10112, 0);
G2L["6d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["6d"]["Text"] = [[Enter your desired fov.]];
G2L["6d"]["Name"] = [[fovtext]];
G2L["6d"]["Position"] = UDim2.new(0.32761, 0, 0.12451, 0);


-- StarterGui.Watermark.fresh.Aimbot.fovtext.UIGradient
G2L["6e"] = Instance.new("UIGradient", G2L["6d"]);
G2L["6e"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Aimbot.fovtext.gradient
G2L["6f"] = Instance.new("LocalScript", G2L["6d"]);
G2L["6f"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Aimbot.smoothtext
G2L["70"] = Instance.new("TextLabel", G2L["4f"]);
G2L["70"]["BorderSizePixel"] = 0;
G2L["70"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["70"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["70"]["TextSize"] = 14;
G2L["70"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["70"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["70"]["BackgroundTransparency"] = 1;
G2L["70"]["Size"] = UDim2.new(0.39559, 0, -0.10112, 0);
G2L["70"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["70"]["Text"] = [[Enter your desired smoothness value.]];
G2L["70"]["Name"] = [[smoothtext]];
G2L["70"]["Position"] = UDim2.new(0.32761, 0, 0.27895, 0);


-- StarterGui.Watermark.fresh.Aimbot.smoothtext.UIGradient
G2L["71"] = Instance.new("UIGradient", G2L["70"]);
G2L["71"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Aimbot.smoothtext.gradient
G2L["72"] = Instance.new("LocalScript", G2L["70"]);
G2L["72"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Aimbot.smoothtext
G2L["73"] = Instance.new("TextLabel", G2L["4f"]);
G2L["73"]["BorderSizePixel"] = 0;
G2L["73"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["73"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["73"]["TextSize"] = 14;
G2L["73"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["73"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["73"]["BackgroundTransparency"] = 1;
G2L["73"]["Size"] = UDim2.new(0.62477, 0, -0.09735, 0);
G2L["73"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["73"]["Text"] = [[Enter your desired prediction factor. (use 0 for basic games.)]];
G2L["73"]["Name"] = [[smoothtext]];
G2L["73"]["Position"] = UDim2.new(0.32933, 0, 0.4229, 0);


-- StarterGui.Watermark.fresh.Aimbot.smoothtext.UIGradient
G2L["74"] = Instance.new("UIGradient", G2L["73"]);
G2L["74"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Aimbot.smoothtext.gradient
G2L["75"] = Instance.new("LocalScript", G2L["73"]);
G2L["75"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Aimbot.Health
G2L["76"] = Instance.new("TextButton", G2L["4f"]);
G2L["76"]["BorderSizePixel"] = 0;
G2L["76"]["TextSize"] = 14;
G2L["76"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
G2L["76"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
G2L["76"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["76"]["Size"] = UDim2.new(0.04859, 0, 0.09022, 0);
G2L["76"]["BackgroundTransparency"] = 0.6;
G2L["76"]["Name"] = [[Health]];
G2L["76"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["76"]["Text"] = [[]];
G2L["76"]["Position"] = UDim2.new(0.08076, 0, 0.69821, 0);


-- StarterGui.Watermark.fresh.Aimbot.Health.UICorner
G2L["77"] = Instance.new("UICorner", G2L["76"]);



-- StarterGui.Watermark.fresh.Aimbot.Health.ring
G2L["78"] = Instance.new("LocalScript", G2L["76"]);
G2L["78"]["Name"] = [[ring]];


-- StarterGui.Watermark.fresh.Aimbot.Health.click
G2L["79"] = Instance.new("LocalScript", G2L["76"]);
G2L["79"]["Name"] = [[click]];


-- StarterGui.Watermark.fresh.Aimbot.Health.UIStroke
G2L["7a"] = Instance.new("UIStroke", G2L["76"]);
G2L["7a"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["7a"]["Thickness"] = 1.2;
G2L["7a"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Aimbot.Distance
G2L["7b"] = Instance.new("TextButton", G2L["4f"]);
G2L["7b"]["BorderSizePixel"] = 0;
G2L["7b"]["TextSize"] = 14;
G2L["7b"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
G2L["7b"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
G2L["7b"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["7b"]["Size"] = UDim2.new(0.04859, 0, 0.09022, 0);
G2L["7b"]["BackgroundTransparency"] = 0.6;
G2L["7b"]["Name"] = [[Distance]];
G2L["7b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["7b"]["Text"] = [[]];
G2L["7b"]["Position"] = UDim2.new(0.08076, 0, 0.82579, 0);


-- StarterGui.Watermark.fresh.Aimbot.Distance.UICorner
G2L["7c"] = Instance.new("UICorner", G2L["7b"]);



-- StarterGui.Watermark.fresh.Aimbot.Distance.ring
G2L["7d"] = Instance.new("LocalScript", G2L["7b"]);
G2L["7d"]["Name"] = [[ring]];


-- StarterGui.Watermark.fresh.Aimbot.Distance.click
G2L["7e"] = Instance.new("LocalScript", G2L["7b"]);
G2L["7e"]["Name"] = [[click]];


-- StarterGui.Watermark.fresh.Aimbot.Distance.UIStroke
G2L["7f"] = Instance.new("UIStroke", G2L["7b"]);
G2L["7f"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["7f"]["Thickness"] = 1.2;
G2L["7f"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Aimbot.distancee
G2L["80"] = Instance.new("TextBox", G2L["4f"]);
G2L["80"]["CursorPosition"] = -1;
G2L["80"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["80"]["BorderSizePixel"] = 0;
G2L["80"]["TextWrapped"] = true;
G2L["80"]["TextSize"] = 14;
G2L["80"]["Name"] = [[distancee]];
G2L["80"]["TextScaled"] = true;
G2L["80"]["BackgroundColor3"] = Color3.fromRGB(53, 53, 53);
G2L["80"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["80"]["Size"] = UDim2.new(0.22618, 0, 0.0929, 0);
G2L["80"]["Position"] = UDim2.new(0.144, 0, 0.82876, 0);
G2L["80"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["80"]["Text"] = [[Max Distance]];
G2L["80"]["BackgroundTransparency"] = 0.6;


-- StarterGui.Watermark.fresh.Aimbot.distancee.LocalScript
G2L["81"] = Instance.new("LocalScript", G2L["80"]);



-- StarterGui.Watermark.fresh.Aimbot.distancee.UICorner
G2L["82"] = Instance.new("UICorner", G2L["80"]);
G2L["82"]["CornerRadius"] = UDim.new(0.2, 0);


-- StarterGui.Watermark.fresh.Aimbot.distancee.UIStroke
G2L["83"] = Instance.new("UIStroke", G2L["80"]);
G2L["83"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["83"]["Thickness"] = 1.2;
G2L["83"]["Color"] = Color3.fromRGB(161, 33, 241);


-- StarterGui.Watermark.fresh.Aimbot.Health
G2L["84"] = Instance.new("TextLabel", G2L["4f"]);
G2L["84"]["BorderSizePixel"] = 0;
G2L["84"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["84"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["84"]["TextSize"] = 14;
G2L["84"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["84"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["84"]["BackgroundTransparency"] = 1;
G2L["84"]["Size"] = UDim2.new(0.2405, 0, -0.10112, 0);
G2L["84"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["84"]["Text"] = [[Targets lowest health]];
G2L["84"]["Name"] = [[Health]];
G2L["84"]["Position"] = UDim2.new(0.14495, 0, 0.79599, 0);


-- StarterGui.Watermark.fresh.Aimbot.Health.UIGradient
G2L["85"] = Instance.new("UIGradient", G2L["84"]);
G2L["85"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Aimbot.Health.gradient
G2L["86"] = Instance.new("LocalScript", G2L["84"]);
G2L["86"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Aimbot.disable
G2L["87"] = Instance.new("TextLabel", G2L["4f"]);
G2L["87"]["BorderSizePixel"] = 0;
G2L["87"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["87"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["87"]["TextSize"] = 14;
G2L["87"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["87"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["87"]["BackgroundTransparency"] = 1;
G2L["87"]["Size"] = UDim2.new(0.40898, 0, -0.10112, 0);
G2L["87"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["87"]["Text"] = [[Maximum distance the aimbot targets.]];
G2L["87"]["Name"] = [[disable]];
G2L["87"]["Position"] = UDim2.new(0.38447, 0, 0.92357, 0);


-- StarterGui.Watermark.fresh.Aimbot.disable.UIGradient
G2L["88"] = Instance.new("UIGradient", G2L["87"]);
G2L["88"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Aimbot.disable.gradient
G2L["89"] = Instance.new("LocalScript", G2L["87"]);
G2L["89"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Main
G2L["8a"] = Instance.new("Frame", G2L["21"]);
G2L["8a"]["Visible"] = false;
G2L["8a"]["ZIndex"] = 2;
G2L["8a"]["BorderSizePixel"] = 0;
G2L["8a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["8a"]["Size"] = UDim2.new(0.78448, 0, 0.99901, 0);
G2L["8a"]["Position"] = UDim2.new(0.1982, 0, 0.03118, 0);
G2L["8a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["8a"]["Name"] = [[Main]];
G2L["8a"]["BackgroundTransparency"] = 1;


-- StarterGui.Watermark.fresh.Main.ImageLabel
G2L["8b"] = Instance.new("ImageLabel", G2L["8a"]);
G2L["8b"]["ZIndex"] = 0;
G2L["8b"]["BorderSizePixel"] = 0;
G2L["8b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["8b"]["ImageTransparency"] = 0.82;
G2L["8b"]["ImageColor3"] = Color3.fromRGB(163, 0, 255);
G2L["8b"]["Image"] = [[rbxassetid://12928552195]];
G2L["8b"]["Size"] = UDim2.new(0.99756, 0, 0.94634, 0);
G2L["8b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["8b"]["BackgroundTransparency"] = 1;
G2L["8b"]["Position"] = UDim2.new(0, 0, -0.01007, 0);


-- StarterGui.Watermark.fresh.Main.welcome
G2L["8c"] = Instance.new("TextLabel", G2L["8a"]);
G2L["8c"]["BorderSizePixel"] = 0;
G2L["8c"]["SelectionOrder"] = 1;
G2L["8c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["8c"]["TextSize"] = 14;
G2L["8c"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["8c"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["8c"]["BackgroundTransparency"] = 1;
G2L["8c"]["Size"] = UDim2.new(0.9918, 0, -0.08729, 0);
G2L["8c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["8c"]["Text"] = [[Welcome to zonex.]];
G2L["8c"]["Name"] = [[welcome]];
G2L["8c"]["Position"] = UDim2.new(0.0041, 0, 0.08685, 0);


-- StarterGui.Watermark.fresh.Main.welcome.UIGradient
G2L["8d"] = Instance.new("UIGradient", G2L["8c"]);
G2L["8d"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Main.welcome.gradient
G2L["8e"] = Instance.new("LocalScript", G2L["8c"]);
G2L["8e"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Main.welcome.LocalScript
G2L["8f"] = Instance.new("LocalScript", G2L["8c"]);



-- StarterGui.Watermark.fresh.Main.meow
G2L["90"] = Instance.new("TextLabel", G2L["8a"]);
G2L["90"]["TextWrapped"] = true;
G2L["90"]["BorderSizePixel"] = 0;
G2L["90"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["90"]["TextSize"] = 14;
G2L["90"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["90"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["90"]["BackgroundTransparency"] = 1;
G2L["90"]["Size"] = UDim2.new(0.9918, 0, -0.12043, 0);
G2L["90"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["90"]["Text"] = [[This script is and always has been free. If someone sold you this script, then you got scammed. This script has been tested and is supported on several games.]];
G2L["90"]["Name"] = [[meow]];
G2L["90"]["Position"] = UDim2.new(-0.00226, 0, 0.2413, 0);


-- StarterGui.Watermark.fresh.Main.meow.UIGradient
G2L["91"] = Instance.new("UIGradient", G2L["90"]);
G2L["91"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Main.meow.gradient
G2L["92"] = Instance.new("LocalScript", G2L["90"]);
G2L["92"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Main.Main2
G2L["93"] = Instance.new("Frame", G2L["8a"]);
G2L["93"]["ZIndex"] = 2;
G2L["93"]["BorderSizePixel"] = 0;
G2L["93"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["93"]["Size"] = UDim2.new(0.99407, 0, 0.4225, 0);
G2L["93"]["Position"] = UDim2.new(0.00348, 0, 0.32566, 0);
G2L["93"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["93"]["Name"] = [[Main2]];
G2L["93"]["BackgroundTransparency"] = 1;


-- StarterGui.Watermark.fresh.Main.Main2.game
G2L["94"] = Instance.new("TextLabel", G2L["93"]);
G2L["94"]["TextWrapped"] = true;
G2L["94"]["BorderSizePixel"] = 0;
G2L["94"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["94"]["TextSize"] = 14;
G2L["94"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["94"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["94"]["BackgroundTransparency"] = 1;
G2L["94"]["Size"] = UDim2.new(0.14573, 0, -0.12043, 0);
G2L["94"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["94"]["Text"] = [[- Rivals ✅]];
G2L["94"]["Name"] = [[game]];
G2L["94"]["Position"] = UDim2.new(-0.00226, 0, 0.38231, 0);


-- StarterGui.Watermark.fresh.Main.Main2.game.UIGradient
G2L["95"] = Instance.new("UIGradient", G2L["94"]);
G2L["95"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Main.Main2.game.gradient
G2L["96"] = Instance.new("LocalScript", G2L["94"]);
G2L["96"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Main.Main2.game
G2L["97"] = Instance.new("TextLabel", G2L["93"]);
G2L["97"]["TextWrapped"] = true;
G2L["97"]["BorderSizePixel"] = 0;
G2L["97"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["97"]["TextSize"] = 14;
G2L["97"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["97"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["97"]["BackgroundTransparency"] = 1;
G2L["97"]["Size"] = UDim2.new(0.14573, 0, -0.12043, 0);
G2L["97"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["97"]["Text"] = [[- Da hood ⚠️⚙️]];
G2L["97"]["Name"] = [[game]];
G2L["97"]["Position"] = UDim2.new(0.42713, 0, 0.23161, 0);


-- StarterGui.Watermark.fresh.Main.Main2.game.UIGradient
G2L["98"] = Instance.new("UIGradient", G2L["97"]);
G2L["98"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Main.Main2.game.gradient
G2L["99"] = Instance.new("LocalScript", G2L["97"]);
G2L["99"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Main.Main2.game
G2L["9a"] = Instance.new("TextLabel", G2L["93"]);
G2L["9a"]["TextWrapped"] = true;
G2L["9a"]["BorderSizePixel"] = 0;
G2L["9a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["9a"]["TextSize"] = 14;
G2L["9a"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["9a"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["9a"]["BackgroundTransparency"] = 1;
G2L["9a"]["Size"] = UDim2.new(0.1957, 0, -0.12043, 0);
G2L["9a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["9a"]["Text"] = [[- Murder mystery 2 ✅]];
G2L["9a"]["Name"] = [[game]];
G2L["9a"]["Position"] = UDim2.new(0.01669, 0, 0.53003, 0);


-- StarterGui.Watermark.fresh.Main.Main2.game.UIGradient
G2L["9b"] = Instance.new("UIGradient", G2L["9a"]);
G2L["9b"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Main.Main2.game.gradient
G2L["9c"] = Instance.new("LocalScript", G2L["9a"]);
G2L["9c"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Main.Main2.game
G2L["9d"] = Instance.new("TextLabel", G2L["93"]);
G2L["9d"]["TextWrapped"] = true;
G2L["9d"]["BorderSizePixel"] = 0;
G2L["9d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["9d"]["TextSize"] = 14;
G2L["9d"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["9d"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["9d"]["BackgroundTransparency"] = 1;
G2L["9d"]["Size"] = UDim2.new(0.1957, 0, -0.12043, 0);
G2L["9d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["9d"]["Text"] = [[- Basic FPS games. ✅]];
G2L["9d"]["Name"] = [[game]];
G2L["9d"]["Position"] = UDim2.new(0.01669, 0, 0.60725, 0);


-- StarterGui.Watermark.fresh.Main.Main2.game.UIGradient
G2L["9e"] = Instance.new("UIGradient", G2L["9d"]);
G2L["9e"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Main.Main2.game.gradient
G2L["9f"] = Instance.new("LocalScript", G2L["9d"]);
G2L["9f"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Main.Main2.UIListLayout
G2L["a0"] = Instance.new("UIListLayout", G2L["93"]);
G2L["a0"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
G2L["a0"]["VerticalFlex"] = Enum.UIFlexAlignment.Fill;
G2L["a0"]["Padding"] = UDim.new(-0.01, 0);


-- StarterGui.Watermark.fresh.Changelogs1
G2L["a1"] = Instance.new("TextButton", G2L["21"]);
G2L["a1"]["TextWrapped"] = true;
G2L["a1"]["BorderSizePixel"] = 0;
G2L["a1"]["TextSize"] = 14;
G2L["a1"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["a1"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
G2L["a1"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["a1"]["Size"] = UDim2.new(0.17126, 0, 0.06211, 0);
G2L["a1"]["BackgroundTransparency"] = 0.8;
G2L["a1"]["Name"] = [[Changelogs1]];
G2L["a1"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["a1"]["Text"] = [[Changelogs]];
G2L["a1"]["Position"] = UDim2.new(0, 0, 0.20894, 0);


-- StarterGui.Watermark.fresh.Changelogs1.LocalScript
G2L["a2"] = Instance.new("LocalScript", G2L["a1"]);



-- StarterGui.Watermark.fresh.Changelogs
G2L["a3"] = Instance.new("Frame", G2L["21"]);
G2L["a3"]["Visible"] = false;
G2L["a3"]["ZIndex"] = 2;
G2L["a3"]["BorderSizePixel"] = 0;
G2L["a3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["a3"]["Size"] = UDim2.new(0.78448, 0, 0.99901, 0);
G2L["a3"]["Position"] = UDim2.new(0.1982, 0, 0.03118, 0);
G2L["a3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["a3"]["Name"] = [[Changelogs]];
G2L["a3"]["BackgroundTransparency"] = 1;


-- StarterGui.Watermark.fresh.Changelogs.ImageLabel
G2L["a4"] = Instance.new("ImageLabel", G2L["a3"]);
G2L["a4"]["ZIndex"] = 0;
G2L["a4"]["BorderSizePixel"] = 0;
G2L["a4"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["a4"]["ImageTransparency"] = 0.82;
G2L["a4"]["ImageColor3"] = Color3.fromRGB(163, 0, 255);
G2L["a4"]["Image"] = [[rbxassetid://12928552195]];
G2L["a4"]["Size"] = UDim2.new(0.99756, 0, 0.94634, 0);
G2L["a4"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["a4"]["BackgroundTransparency"] = 1;
G2L["a4"]["Position"] = UDim2.new(0, 0, -0.01007, 0);


-- StarterGui.Watermark.fresh.Changelogs.meow
G2L["a5"] = Instance.new("TextLabel", G2L["a3"]);
G2L["a5"]["TextWrapped"] = true;
G2L["a5"]["BorderSizePixel"] = 0;
G2L["a5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["a5"]["TextSize"] = 14;
G2L["a5"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["a5"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["a5"]["BackgroundTransparency"] = 1;
G2L["a5"]["Size"] = UDim2.new(0.9918, 0, -0.12043, 0);
G2L["a5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["a5"]["Text"] = [[NEW V2 VERSION RELEASED!! OMGGG]];
G2L["a5"]["Name"] = [[meow]];
G2L["a5"]["Position"] = UDim2.new(-0.00054, 0, 0.12043, 0);


-- StarterGui.Watermark.fresh.Changelogs.meow.UIGradient
G2L["a6"] = Instance.new("UIGradient", G2L["a5"]);
G2L["a6"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Changelogs.meow.gradient
G2L["a7"] = Instance.new("LocalScript", G2L["a5"]);
G2L["a7"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Changelogs.Main2
G2L["a8"] = Instance.new("Frame", G2L["a3"]);
G2L["a8"]["ZIndex"] = 2;
G2L["a8"]["BorderSizePixel"] = 0;
G2L["a8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["a8"]["Size"] = UDim2.new(0.99407, 0, 0.38265, 0);
G2L["a8"]["Position"] = UDim2.new(0.00348, 0, 0.27823, 0);
G2L["a8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["a8"]["Name"] = [[Main2]];
G2L["a8"]["BackgroundTransparency"] = 1;


-- StarterGui.Watermark.fresh.Changelogs.Main2.game
G2L["a9"] = Instance.new("TextLabel", G2L["a8"]);
G2L["a9"]["TextWrapped"] = true;
G2L["a9"]["BorderSizePixel"] = 0;
G2L["a9"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["a9"]["TextSize"] = 14;
G2L["a9"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["a9"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["a9"]["BackgroundTransparency"] = 1;
G2L["a9"]["Size"] = UDim2.new(0.31561, 0, 0.14484, 0);
G2L["a9"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["a9"]["Text"] = [[- general performance enhancements]];
G2L["a9"]["Name"] = [[game]];
G2L["a9"]["Position"] = UDim2.new(0.3422, 0, 0.0682, 0);


-- StarterGui.Watermark.fresh.Changelogs.Main2.game.UIGradient
G2L["aa"] = Instance.new("UIGradient", G2L["a9"]);
G2L["aa"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Changelogs.Main2.game.gradient
G2L["ab"] = Instance.new("LocalScript", G2L["a9"]);
G2L["ab"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Changelogs.Main2.game
G2L["ac"] = Instance.new("TextLabel", G2L["a8"]);
G2L["ac"]["TextWrapped"] = true;
G2L["ac"]["BorderSizePixel"] = 0;
G2L["ac"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["ac"]["TextSize"] = 14;
G2L["ac"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["ac"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["ac"]["BackgroundTransparency"] = 1;
G2L["ac"]["Size"] = UDim2.new(0.36755, 0, 0.09755, 0);
G2L["ac"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["ac"]["Text"] = [[- humanized aimbot for da hood]];
G2L["ac"]["Name"] = [[game]];
G2L["ac"]["Position"] = UDim2.new(0.31623, 0, 0.24348, 0);


-- StarterGui.Watermark.fresh.Changelogs.Main2.game.UIGradient
G2L["ad"] = Instance.new("UIGradient", G2L["ac"]);
G2L["ad"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Changelogs.Main2.game.gradient
G2L["ae"] = Instance.new("LocalScript", G2L["ac"]);
G2L["ae"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Changelogs.Main2.game
G2L["af"] = Instance.new("TextLabel", G2L["a8"]);
G2L["af"]["TextWrapped"] = true;
G2L["af"]["BorderSizePixel"] = 0;
G2L["af"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["af"]["TextSize"] = 14;
G2L["af"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["af"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["af"]["BackgroundTransparency"] = 1;
G2L["af"]["Size"] = UDim2.new(0.33091, 0, 0.01, 0);
G2L["af"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["af"]["Text"] = [[- bug fixes]];
G2L["af"]["Name"] = [[game]];
G2L["af"]["Position"] = UDim2.new(0.33454, 0, 0.51963, 0);


-- StarterGui.Watermark.fresh.Changelogs.Main2.game.UIGradient
G2L["b0"] = Instance.new("UIGradient", G2L["af"]);
G2L["b0"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Changelogs.Main2.game.gradient
G2L["b1"] = Instance.new("LocalScript", G2L["af"]);
G2L["b1"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Changelogs.Main2.game
G2L["b2"] = Instance.new("TextLabel", G2L["a8"]);
G2L["b2"]["TextWrapped"] = true;
G2L["b2"]["BorderSizePixel"] = 0;
G2L["b2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["b2"]["TextSize"] = 14;
G2L["b2"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["b2"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["b2"]["BackgroundTransparency"] = 1;
G2L["b2"]["Size"] = UDim2.new(0.1957, 0, -0.12043, 0);
G2L["b2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["b2"]["Text"] = [[- ui improvements]];
G2L["b2"]["Name"] = [[game]];
G2L["b2"]["Position"] = UDim2.new(0.01669, 0, 0.60725, 0);


-- StarterGui.Watermark.fresh.Changelogs.Main2.game.UIGradient
G2L["b3"] = Instance.new("UIGradient", G2L["b2"]);
G2L["b3"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.Changelogs.Main2.game.gradient
G2L["b4"] = Instance.new("LocalScript", G2L["b2"]);
G2L["b4"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.Changelogs.Main2.UIListLayout
G2L["b5"] = Instance.new("UIListLayout", G2L["a8"]);
G2L["b5"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
G2L["b5"]["VerticalFlex"] = Enum.UIFlexAlignment.Fill;
G2L["b5"]["Padding"] = UDim.new(-0.01, 0);


-- StarterGui.Watermark.fresh.Sound
G2L["b6"] = Instance.new("Sound", G2L["21"]);
G2L["b6"]["RollOffMode"] = Enum.RollOffMode.InverseTapered;
G2L["b6"]["SoundId"] = [[rbxassetid://15675059323]];


-- StarterGui.Watermark.fresh.contact
G2L["b7"] = Instance.new("Frame", G2L["21"]);
G2L["b7"]["BorderSizePixel"] = 0;
G2L["b7"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
G2L["b7"]["Size"] = UDim2.new(0.17126, 0, 0.13752, 0);
G2L["b7"]["Position"] = UDim2.new(0, 0, 0.85913, 0);
G2L["b7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["b7"]["Name"] = [[contact]];
G2L["b7"]["BackgroundTransparency"] = 0.8;


-- StarterGui.Watermark.fresh.contact.zonesafe
G2L["b8"] = Instance.new("TextLabel", G2L["b7"]);
G2L["b8"]["BorderSizePixel"] = 0;
G2L["b8"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["b8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["b8"]["TextSize"] = 14;
G2L["b8"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["b8"]["TextColor3"] = Color3.fromRGB(161, 33, 241);
G2L["b8"]["BackgroundTransparency"] = 1;
G2L["b8"]["Size"] = UDim2.new(0.37433, 0, -1, 0);
G2L["b8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["b8"]["Text"] = [[zonesafe]];
G2L["b8"]["Name"] = [[zonesafe]];
G2L["b8"]["Position"] = UDim2.new(0.4757, 0, 1, 0);


-- StarterGui.Watermark.fresh.contact.zonesafe.UIGradient
G2L["b9"] = Instance.new("UIGradient", G2L["b8"]);
G2L["b9"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(161, 33, 241)),ColorSequenceKeypoint.new(0.385, Color3.fromRGB(248, 248, 248)),ColorSequenceKeypoint.new(0.542, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 34, 255))};


-- StarterGui.Watermark.fresh.contact.zonesafe.gradient
G2L["ba"] = Instance.new("LocalScript", G2L["b8"]);
G2L["ba"]["Name"] = [[gradient]];


-- StarterGui.Watermark.fresh.contact.ImageLabel
G2L["bb"] = Instance.new("ImageLabel", G2L["b7"]);
G2L["bb"]["BorderSizePixel"] = 0;
G2L["bb"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["bb"]["Image"] = [[http://www.roblox.com/asset/?id=114286232288065]];
G2L["bb"]["Size"] = UDim2.new(0.35522, 0, 0.9, 0);
G2L["bb"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["bb"]["Position"] = UDim2.new(0.0561, 0, 0.04878, 0);


-- StarterGui.Watermark.fresh.contact.ImageLabel.UICorner
G2L["bc"] = Instance.new("UICorner", G2L["bb"]);
G2L["bc"]["CornerRadius"] = UDim.new(0.8, 0);


-- StarterGui.Watermark.initial.outline.zonex.gradient
local function C_6()
local script = G2L["6"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_6);
-- StarterGui.Watermark.initial.outline.time.gradient
local function C_b()
local script = G2L["b"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_b);
-- StarterGui.Watermark.initial.outline.time.time
local function C_c()
local script = G2L["c"];
	-- Place this LocalScript in a GUI TextLabel
	local textLabel = script.Parent -- Ensure the script's parent is a TextLabel
	
	-- Function to format time with leading zeros
	local function formatTime(unit)
		return string.format("%02d", unit)
	end
	
	-- Update the time every second
	while true do
		local currentTime = os.date("*t") -- Get the local time
		local hours = currentTime.hour
		local minutes = currentTime.min
		local seconds = currentTime.sec
	
		-- Format the time as HH:MM:SS
		local formattedTime = formatTime(hours) .. ":" .. formatTime(minutes) .. ":" .. formatTime(seconds)
	
		-- Set the TextLabel text to the current time
		textLabel.Text = formattedTime
	
		wait(1) -- Wait for 1 second before updating
	end
	
end;
task.spawn(C_c);
-- StarterGui.Watermark.initial.outline.gradient
local function C_d()
local script = G2L["d"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_d);
-- StarterGui.Watermark.initial.drag
local function C_12()
local script = G2L["12"];
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	
	local gui = script.Parent
	
	local dragging
	local dragInput
	local dragStart
	local startPos
	local targetPos -- Target position for tweening
	local dragTween -- Active tween
	
	local function update(input)
		local delta = input.Position - dragStart
		targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	
		-- Cancel any existing tween
		if dragTween then
			dragTween:Cancel()
		end
	
		-- Create a new tween for smooth movement
		dragTween = TweenService:Create(
			gui, -- The GUI object
			TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), -- Smooth tween
			{ Position = targetPos } -- Target position
		)
		dragTween:Play()
	end
	
	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = gui.Position
	
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	gui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	
end;
task.spawn(C_12);
-- StarterGui.Watermark.musica.drag
local function C_18()
local script = G2L["18"];
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	
	local gui = script.Parent
	
	local dragging
	local dragInput
	local dragStart
	local startPos
	local targetPos -- Target position for tweening
	local dragTween -- Active tween
	
	local function update(input)
		local delta = input.Position - dragStart
		targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	
		-- Cancel any existing tween
		if dragTween then
			dragTween:Cancel()
		end
	
		-- Create a new tween for smooth movement
		dragTween = TweenService:Create(
			gui, -- The GUI object
			TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), -- Smooth tween
			{ Position = targetPos } -- Target position
		)
		dragTween:Play()
	end
	
	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = gui.Position
	
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	gui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	
end;
task.spawn(C_18);
-- StarterGui.Watermark.pressv
local function C_20()
local script = G2L["20"];
	-- Place this LocalScript in StarterPlayerScripts or StarterGui
	local screenGui = script.Parent -- Replace 'YourScreenGui' with the name of your ScreenGui
	local toggleKey = Enum.KeyCode.V -- Replace 'F' with the key you want to toggle
	
	local UserInputService = game:GetService("UserInputService")
	
	-- Function to toggle the visibility of the ScreenGui
	local function toggleGui()
		screenGui.Enabled = not screenGui.Enabled
	end
	
	-- Listen for key press events
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end -- Ignore inputs processed by the game
	
		if input.KeyCode == toggleKey then
			toggleGui()
		end
	end)
	
end;
task.spawn(C_20);
-- StarterGui.Watermark.fresh.drag
local function C_26()
local script = G2L["26"];
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	
	local gui = script.Parent
	
	local dragging
	local dragInput
	local dragStart
	local startPos
	local targetPos -- Target position for tweening
	local dragTween -- Active tween
	
	local function update(input)
		local delta = input.Position - dragStart
		targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	
		-- Cancel any existing tween
		if dragTween then
			dragTween:Cancel()
		end
	
		-- Create a new tween for smooth movement
		dragTween = TweenService:Create(
			gui, -- The GUI object
			TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), -- Smooth tween
			{ Position = targetPos } -- Target position
		)
		dragTween:Play()
	end
	
	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = gui.Position
	
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	gui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	
end;
task.spawn(C_26);
-- StarterGui.Watermark.fresh.Misc.highlight.highlight
local function C_2c()
local script = G2L["2c"];
	-- Reference to the button and local variable
	local button = script.Parent-- Make sure to set the button's name in Roblox Studio
	 -- Initialize the local variable
	highlightEnabled = false
	
	-- Define color options for toggling
	local color1 = Color3.fromRGB(255, 0, 0)  -- Red color
	local color2 = Color3.fromRGB(0, 255, 0)  -- Green color
	
	-- Function to toggle the color and variable
	local function toggle()
		-- Toggle the button color
		if button.BackgroundColor3 == color1 then
			button.BackgroundColor3 = color2
		else
			button.BackgroundColor3 = color1
		end
	
		-- Toggle the local variable
		highlightEnabled = not highlightEnabled
		print("Toggle Value: " .. tostring(highlightEnabled))  -- Print the current value of the variable
	end
	
	-- Connect the function to the button's MouseButton1Click event (left-click)
	button.MouseButton1Click:Connect(toggle)
	
end;
task.spawn(C_2c);
-- StarterGui.Watermark.fresh.Misc.highlight.click
local function C_2d()
local script = G2L["2d"];
	local function click()
		script.Parent.Parent.Parent.Sound:Play()
	end
	script.Parent.MouseButton1Down:Connect(click)
end;
task.spawn(C_2d);
-- StarterGui.Watermark.fresh.Misc.circle.ring
local function C_31()
local script = G2L["31"];
	-- Reference to the button and local variable
	local button = script.Parent-- Make sure to set the button's name in Roblox Studio
	 -- Initialize the local variable
	FOVring.Visible = false
	
	-- Define color options for toggling
	local color1 = Color3.fromRGB(255, 0, 0)  -- Red color
	local color2 = Color3.fromRGB(0, 255, 0)  -- Green color
	
	-- Function to toggle the color and variable
	local function toggle()
		-- Toggle the button color
		if button.BackgroundColor3 == color1 then
			button.BackgroundColor3 = color2
		else
			button.BackgroundColor3 = color1
		end
	
		-- Toggle the local variable
		FOVring.Visible = not FOVring.Visible
		print("Toggle Value: " .. tostring(FOVring.Visible))  -- Print the current value of the variable
	end
	
	-- Connect the function to the button's MouseButton1Click event (left-click)
	button.MouseButton1Click:Connect(toggle)
	
end;
task.spawn(C_31);
-- StarterGui.Watermark.fresh.Misc.circle.click
local function C_32()
local script = G2L["32"];
	local function click()
		script.Parent.Parent.Parent.Sound:Play()
	end
	script.Parent.MouseButton1Down:Connect(click)
end;
task.spawn(C_32);
-- StarterGui.Watermark.fresh.Misc.team.LocalScript
local function C_36()
local script = G2L["36"];
	-- Reference to the button and local variable
	local button = script.Parent  -- Make sure to set the button's name in Roblox Studio
	teamCheck = false  -- Initialize the local variable
	
	-- Define color options for toggling
	local color1 = Color3.fromRGB(255, 0, 0)  -- Red color
	local color2 = Color3.fromRGB(0, 255, 0)  -- Green color
	
	-- Function to toggle the color and variable
	local function toggle()
		-- Toggle the button color
		if button.BackgroundColor3 == color1 then
			button.BackgroundColor3 = color2
		else
			button.BackgroundColor3 = color1
		end
	
		-- Toggle the local variable
		teamCheck = not teamCheck
		print("Toggle Value: " .. tostring(teamCheck))  -- Print the current value of the variable
	end
	
	-- Connect the function to the button's MouseButton1Click event (left-click)
	button.MouseButton1Click:Connect(toggle)
	
end;
task.spawn(C_36);
-- StarterGui.Watermark.fresh.Misc.team.click
local function C_37()
local script = G2L["37"];
	local function click()
		script.Parent.Parent.Parent.Sound:Play()
	end
	script.Parent.MouseButton1Down:Connect(click)
end;
task.spawn(C_37);
-- StarterGui.Watermark.fresh.Misc.fovtext.gradient
local function C_3b()
local script = G2L["3b"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_3b);
-- StarterGui.Watermark.fresh.Misc.teamtext.gradient
local function C_3e()
local script = G2L["3e"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_3e);
-- StarterGui.Watermark.fresh.Misc.highlightTEXT.gradient
local function C_41()
local script = G2L["41"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_41);
-- StarterGui.Watermark.fresh.Misc.esp.ring
local function C_45()
local script = G2L["45"];
	-- Reference to the button and local variable
	local button = script.Parent-- Make sure to set the button's name in Roblox Studio
	 -- Initialize the local variable
	ESPEnabled = false
	
	-- Define color options for toggling
	local color1 = Color3.fromRGB(255, 0, 0)  -- Red color
	local color2 = Color3.fromRGB(0, 255, 0)  -- Green color
	
	-- Function to toggle the color and variable
	local function toggle()
		-- Toggle the button color
		if button.BackgroundColor3 == color1 then
			button.BackgroundColor3 = color2
		else
			button.BackgroundColor3 = color1
		end
	
		-- Toggle the local variable
		ESPEnabled = not ESPEnabled
		print("Toggle Value: " .. tostring(ESPEnabled))  -- Print the current value of the variable
	end
	
	-- Connect the function to the button's MouseButton1Click event (left-click)
	button.MouseButton1Click:Connect(toggle)
	
end;
task.spawn(C_45);
-- StarterGui.Watermark.fresh.Misc.esp.click
local function C_46()
local script = G2L["46"];
	local function click()
		script.Parent.Parent.Parent.Sound:Play()
	end
	script.Parent.MouseButton1Down:Connect(click)
end;
task.spawn(C_46);
-- StarterGui.Watermark.fresh.Misc.fovtext.gradient
local function C_4a()
local script = G2L["4a"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_4a);
-- StarterGui.Watermark.fresh.Combat.LocalScript
local function C_4c()
local script = G2L["4c"];
	
	
	-- Define the frames
	local mainFrame = script.Parent.Parent.Main
	local aimbotFrame = script.Parent.Parent.Aimbot
	local changelogsFrame = script.Parent.Parent.Changelogs
	local miscFrame = script.Parent.Parent.Misc
	
	-- Table of frames
	local frames = {mainFrame, aimbotFrame, changelogsFrame, miscFrame}
	
	-- Function to toggle visibility
	local function toggleVisibility(selectedFrame)
		for _, frame in ipairs(frames) do
			if frame == selectedFrame then
				frame.Visible = true
			else
				frame.Visible = false
			end
		end
	end
	
	-- Example button logic
	script.Parent.MouseButton1Click:Connect(function()
		-- Specify which frame to make visible
		local frameToShow = aimbotFrame -- Change this to the desired frame
		frameToShow.Visible = true
		script.Parent.Parent.Sound:Play()
	
		-- Toggle visibility
		toggleVisibility(frameToShow)
	end)
	
end;
task.spawn(C_4c);
-- StarterGui.Watermark.fresh.Visuals.LocalScript
local function C_4e()
local script = G2L["4e"];
	
	
	-- Define the frames
	local mainFrame = script.Parent.Parent.Main
	local aimbotFrame = script.Parent.Parent.Aimbot
	local changelogsFrame = script.Parent.Parent.Changelogs
	local miscFrame = script.Parent.Parent.Misc
	
	-- Table of frames
	local frames = {mainFrame, aimbotFrame, changelogsFrame, miscFrame}
	
	-- Function to toggle visibility
	local function toggleVisibility(selectedFrame)
		for _, frame in ipairs(frames) do
			if frame == selectedFrame then
				frame.Visible = true
			else
				frame.Visible = false
			end
		end
	end
	
	-- Example button logic
	script.Parent.MouseButton1Click:Connect(function()
		-- Specify which frame to make visible
		local frameToShow = miscFrame -- Change this to the desired frame
		frameToShow.Visible = true
		script.Parent.Parent.Sound:Play()
	
		-- Toggle visibility
		toggleVisibility(frameToShow)
	end)
	
end;
task.spawn(C_4e);
-- StarterGui.Watermark.fresh.Aimbot.fov.LocalScript
local function C_52()
local script = G2L["52"];
	-- Reference to the TextBox and the local variable
	local textBox = script.Parent  -- Ensure the TextBox is named correctly
	fov = 90  -- Initialize the local variable
	
	-- Function to handle the input and update the local variable
	local function onTextChanged()
		-- Try to convert the input to a number
		local number = tonumber(textBox.Text)
	
		if number then
			-- If it's a valid number, update the local variable
			fov = number
			print("Local Variable Updated: " .. tostring(fov))
		else
			-- If the input is not a valid number, print an error message
			print("Invalid input! Please enter a valid number.")
		end
	end
	
	-- Connect the function to the FocusLost event (when the player leaves the TextBox)
	textBox.FocusLost:Connect(onTextChanged)
	
end;
task.spawn(C_52);
-- StarterGui.Watermark.fresh.Aimbot.prediction.LocalScript
local function C_56()
local script = G2L["56"];
	-- Reference to the TextBox and the local variable
	local textBox = script.Parent  -- Ensure the TextBox is named correctly
	predictionFactor = 0.124  -- Initialize the local variable
	
	-- Function to handle the input and update the local variable
	local function onTextChanged()
		-- Try to convert the input to a number
		local number = tonumber(textBox.Text)
	
		if number then
			-- If it's a valid number, update the local variable
			predictionFactor = number
			print("Local Variable Updated: " .. tostring(predictionFactor))
		else
			-- If the input is not a valid number, print an error message
			print("Invalid input! Please enter a valid number.")
		end
	end
	
	-- Connect the function to the FocusLost event (when the player leaves the TextBox)
	textBox.FocusLost:Connect(onTextChanged)
	
end;
task.spawn(C_56);
-- StarterGui.Watermark.fresh.Aimbot.smoothness.LocalScript
local function C_5a()
local script = G2L["5a"];
	-- Reference to the TextBox and the local variable
	local textBox = script.Parent  -- Ensure the TextBox is named correctly
	smoothing = 0.1  -- Initialize the local variable
	
	-- Function to handle the input and update the local variable
	local function onTextChanged()
		-- Try to convert the input to a number
		local number = tonumber(textBox.Text)
	
		if number then
			-- If it's a valid number, update the local variable
			smoothing = number
			print("Local Variable Updated: " .. tostring(smoothing))
		else
			-- If the input is not a valid number, print an error message
			print("Invalid input! Please enter a valid number.")
		end
	end
	
	-- Connect the function to the FocusLost event (when the player leaves the TextBox)
	textBox.FocusLost:Connect(onTextChanged)
	
end;
task.spawn(C_5a);
-- StarterGui.Watermark.fresh.Aimbot.togle.ring
local function C_5f()
local script = G2L["5f"];
	-- Reference to the button and local variable
	local button = script.Parent-- Make sure to set the button's name in Roblox Studio
	 -- Initialize the local variable
	Toggle = false
	
	-- Define color options for toggling
	local color1 = Color3.fromRGB(255, 0, 0)  -- Red color
	local color2 = Color3.fromRGB(0, 255, 0)  -- Green color
	
	-- Function to toggle the color and variable
	local function toggles()
		-- Toggle the button color
		if button.BackgroundColor3 == color1 then
			button.BackgroundColor3 = color2
		else
			button.BackgroundColor3 = color1
		end
	
		-- Toggle the local variable
		Toggle = not Toggle
		print("Toggle Value: " .. tostring(Toggle))  -- Print the current value of the variable
	end
	
	-- Connect the function to the button's MouseButton1Click event (left-click)
	button.MouseButton1Click:Connect(toggles)
	
end;
task.spawn(C_5f);
-- StarterGui.Watermark.fresh.Aimbot.togle.click
local function C_60()
local script = G2L["60"];
	local function click()
		script.Parent.Parent.Parent.Sound:Play()
	end
	script.Parent.MouseButton1Down:Connect(click)
end;
task.spawn(C_60);
-- StarterGui.Watermark.fresh.Aimbot.toggledd.gradient
local function C_64()
local script = G2L["64"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_64);
-- StarterGui.Watermark.fresh.Aimbot.disable.ring
local function C_67()
local script = G2L["67"];
	-- Reference to the button and local variable
	local button = script.Parent-- Make sure to set the button's name in Roblox Studio
	 -- Initialize the local variable
	aimbotEnabled = true
	
	-- Define color options for toggling
	local color1 = Color3.fromRGB(255, 0, 0)  -- Red color
	local color2 = Color3.fromRGB(0, 255, 0)  -- Green color
	
	-- Function to toggle the color and variable
	local function toggles()
		-- Toggle the button color
		if button.BackgroundColor3 == color1 then
			button.BackgroundColor3 = color2
		else
			button.BackgroundColor3 = color1
		end
	
		-- Toggle the local variable
		aimbotEnabled = not aimbotEnabled
		print("Toggle Value: " .. tostring(aimbotEnabled))  -- Print the current value of the variable
	end
	
	-- Connect the function to the button's MouseButton1Click event (left-click)
	button.MouseButton1Click:Connect(toggles)
	
end;
task.spawn(C_67);
-- StarterGui.Watermark.fresh.Aimbot.disable.click
local function C_68()
local script = G2L["68"];
	local function click()
		script.Parent.Parent.Parent.Sound:Play()
	end
	script.Parent.MouseButton1Down:Connect(click)
end;
task.spawn(C_68);
-- StarterGui.Watermark.fresh.Aimbot.disable.gradient
local function C_6c()
local script = G2L["6c"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_6c);
-- StarterGui.Watermark.fresh.Aimbot.fovtext.gradient
local function C_6f()
local script = G2L["6f"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_6f);
-- StarterGui.Watermark.fresh.Aimbot.smoothtext.gradient
local function C_72()
local script = G2L["72"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_72);
-- StarterGui.Watermark.fresh.Aimbot.smoothtext.gradient
local function C_75()
local script = G2L["75"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_75);
-- StarterGui.Watermark.fresh.Aimbot.Health.ring
local function C_78()
local script = G2L["78"];
	-- Reference to the button and local variable
	local button = script.Parent-- Make sure to set the button's name in Roblox Studio
	 -- Initialize the local variable
	useHealthBasedTargeting = false
	
	-- Define color options for toggling
	local color1 = Color3.fromRGB(255, 0, 0)  -- Red color
	local color2 = Color3.fromRGB(0, 255, 0)  -- Green color
	
	-- Function to toggle the color and variable
	local function toggles()
		-- Toggle the button color
		if button.BackgroundColor3 == color1 then
			button.BackgroundColor3 = color2
		else
			button.BackgroundColor3 = color1
		end
	
		-- Toggle the local variable
		useHealthBasedTargeting = not useHealthBasedTargeting
		print("Toggle Value: " .. tostring(useHealthBasedTargeting))  -- Print the current value of the variable
	end
	
	-- Connect the function to the button's MouseButton1Click event (left-click)
	button.MouseButton1Click:Connect(toggles)
	
end;
task.spawn(C_78);
-- StarterGui.Watermark.fresh.Aimbot.Health.click
local function C_79()
local script = G2L["79"];
	local function click()
		script.Parent.Parent.Parent.Sound:Play()
	end
	script.Parent.MouseButton1Down:Connect(click)
end;
task.spawn(C_79);
-- StarterGui.Watermark.fresh.Aimbot.Distance.ring
local function C_7d()
local script = G2L["7d"];
	-- Reference to the button and local variable
	local button = script.Parent-- Make sure to set the button's name in Roblox Studio
	 -- Initialize the local variable
	useDistanceBasedTargeting = false
	
	-- Define color options for toggling
	local color1 = Color3.fromRGB(255, 0, 0)  -- Red color
	local color2 = Color3.fromRGB(0, 255, 0)  -- Green color
	
	-- Function to toggle the color and variable
	local function toggles()
		-- Toggle the button color
		if button.BackgroundColor3 == color1 then
			button.BackgroundColor3 = color2
		else
			button.BackgroundColor3 = color1
		end
	
		-- Toggle the local variable
		useDistanceBasedTargeting = not useDistanceBasedTargeting
		print("Toggle Value: " .. tostring(useDistanceBasedTargeting))  -- Print the current value of the variable
	end
	
	-- Connect the function to the button's MouseButton1Click event (left-click)
	button.MouseButton1Click:Connect(toggles)
	
end;
task.spawn(C_7d);
-- StarterGui.Watermark.fresh.Aimbot.Distance.click
local function C_7e()
local script = G2L["7e"];
	local function click()
		script.Parent.Parent.Parent.Sound:Play()
	end
	script.Parent.MouseButton1Down:Connect(click)
end;
task.spawn(C_7e);
-- StarterGui.Watermark.fresh.Aimbot.distancee.LocalScript
local function C_81()
local script = G2L["81"];
	-- Reference to the TextBox and the local variable
	local textBox = script.Parent  -- Ensure the TextBox is named correctly
	maxDistance = 500  -- Initialize the local variable
	
	-- Function to handle the input and update the local variable
	local function onTextChanged()
		-- Try to convert the input to a number
		local number = tonumber(textBox.Text)
	
		if number then
			-- If it's a valid number, update the local variable
			maxDistance = number
			print("Local Variable Updated: " .. tostring(maxDistance))
		else
			-- If the input is not a valid number, print an error message
			print("Invalid input! Please enter a valid number.")
		end
	end
	
	-- Connect the function to the FocusLost event (when the player leaves the TextBox)
	textBox.FocusLost:Connect(onTextChanged)
	
end;
task.spawn(C_81);
-- StarterGui.Watermark.fresh.Aimbot.Health.gradient
local function C_86()
local script = G2L["86"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_86);
-- StarterGui.Watermark.fresh.Aimbot.disable.gradient
local function C_89()
local script = G2L["89"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_89);
-- StarterGui.Watermark.fresh.Main.welcome.gradient
local function C_8e()
local script = G2L["8e"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_8e);
-- StarterGui.Watermark.fresh.Main.welcome.LocalScript
local function C_8f()
local script = G2L["8f"];
	script.Parent.Text = "Welcome to zonex, " .. game.Players.LocalPlayer.Name .. "!"
end;
task.spawn(C_8f);
-- StarterGui.Watermark.fresh.Main.meow.gradient
local function C_92()
local script = G2L["92"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_92);
-- StarterGui.Watermark.fresh.Main.Main2.game.gradient
local function C_96()
local script = G2L["96"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_96);
-- StarterGui.Watermark.fresh.Main.Main2.game.gradient
local function C_99()
local script = G2L["99"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_99);
-- StarterGui.Watermark.fresh.Main.Main2.game.gradient
local function C_9c()
local script = G2L["9c"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_9c);
-- StarterGui.Watermark.fresh.Main.Main2.game.gradient
local function C_9f()
local script = G2L["9f"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_9f);
-- StarterGui.Watermark.fresh.Changelogs1.LocalScript
local function C_a2()
local script = G2L["a2"];
	
	
	-- Define the frames
	local mainFrame = script.Parent.Parent.Main
	local aimbotFrame = script.Parent.Parent.Aimbot
	local changelogsFrame = script.Parent.Parent.Changelogs
	local miscFrame = script.Parent.Parent.Misc
	
	-- Table of frames
	local frames = {mainFrame, aimbotFrame, changelogsFrame, miscFrame}
	
	-- Function to toggle visibility
	local function toggleVisibility(selectedFrame)
		for _, frame in ipairs(frames) do
			if frame == selectedFrame then
				frame.Visible = true
			else
				frame.Visible = false
			end
		end
	end
	
	-- Example button logic
	script.Parent.MouseButton1Click:Connect(function()
		-- Specify which frame to make visible
		local frameToShow = changelogsFrame -- Change this to the desired frame
		frameToShow.Visible = true
		script.Parent.Parent.Sound:Play()
	
		-- Toggle visibility
		toggleVisibility(frameToShow)
	end)
	
end;
task.spawn(C_a2);
-- StarterGui.Watermark.fresh.Changelogs.meow.gradient
local function C_a7()
local script = G2L["a7"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_a7);
-- StarterGui.Watermark.fresh.Changelogs.Main2.game.gradient
local function C_ab()
local script = G2L["ab"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_ab);
-- StarterGui.Watermark.fresh.Changelogs.Main2.game.gradient
local function C_ae()
local script = G2L["ae"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_ae);
-- StarterGui.Watermark.fresh.Changelogs.Main2.game.gradient
local function C_b1()
local script = G2L["b1"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_b1);
-- StarterGui.Watermark.fresh.Changelogs.Main2.game.gradient
local function C_b4()
local script = G2L["b4"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_b4);
-- StarterGui.Watermark.fresh.contact.zonesafe.gradient
local function C_ba()
local script = G2L["ba"];
	local textLabel = script.Parent -- Ensure the script is under the TextLabel
	local uiGradient = textLabel:FindFirstChild("UIGradient")
	
	while true do
		for i = 0, 1, 0.01 do -- Gradually shift the gradient
			uiGradient.Offset = Vector2.new(i, 0)
			wait(0.01)
		end
	end
	
end;
task.spawn(C_ba);

return G2L["1"], require;
