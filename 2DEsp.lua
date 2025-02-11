local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

getgenv().BoxSettings = {
    Color = Color3.new(1, 0, 0),
    TeamColor = false,
    Thickness = 2,
    Transparency = 1
}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local boxes = {}
getgenv().TwoDBoxesEnabled = true

local function createBox()
    local box = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        table.insert(box, line)
    end
    return box
end

local function updateBox(box, character, targetPlayer)
    if not getgenv().TwoDBoxesEnabled then
        for _, line in ipairs(box) do
            line.Visible = false
        end
        return
    end

    if not character or not character:FindFirstChild("HumanoidRootPart") then
        for _, line in ipairs(box) do
            line.Visible = false
        end
        return
    end

    local rootPart = character.HumanoidRootPart
    local size = Vector3.new(4, 6, 4)
    local corners = {
        rootPart.CFrame * CFrame.new(size.X / 2, size.Y / 2, 0),
        rootPart.CFrame * CFrame.new(-size.X / 2, size.Y / 2, 0),
        rootPart.CFrame * CFrame.new(-size.X / 2, -size.Y / 2, 0),
        rootPart.CFrame * CFrame.new(size.X / 2, -size.Y / 2, 0),
    }

    local function worldToViewportPoint(v)
        local screenPosition, onScreen = camera:WorldToViewportPoint(v.Position)
        return Vector2.new(screenPosition.X, screenPosition.Y), onScreen
    end

    local points = {}
    local onScreen = true
    for _, corner in ipairs(corners) do
        local point, isVisible = worldToViewportPoint(corner)
        table.insert(points, point)
        if not isVisible then
            onScreen = false
        end
    end

    if onScreen then
        local edges = {
            {1, 2}, {2, 3}, {3, 4}, {4, 1},
        }

        for i, edge in ipairs(edges) do
            local startIdx, endIdx = edge[1], edge[2]
            local line = box[i]

            if not BoxSettings.TeamColor then
                line.Color = BoxSettings.Color
            else
                line.Color = targetPlayer.TeamColor.Color
            end

            line.Thickness = BoxSettings.Thickness
            line.Transparency = BoxSettings.Transparency
            line.From = points[startIdx]
            line.To = points[endIdx]
            line.Visible = true
        end
    else
        for _, line in ipairs(box) do
            line.Visible = false
        end
    end
end

local function removeBox(box)
    for _, line in ipairs(box) do
        line:Remove()
    end
end

local function trackPlayer(targetPlayer)
    local function onCharacterAdded(character)
        local box = createBox()
        boxes[targetPlayer] = box

        local humanoid = character:WaitForChild("Humanoid")
        
        humanoid.Died:Connect(function()
            if boxes[targetPlayer] then
                removeBox(boxes[targetPlayer])
                boxes[targetPlayer] = nil
            end
        end)

        RunService.RenderStepped:Connect(function()
            if targetPlayer and targetPlayer.Character == character then
                updateBox(box, character, targetPlayer)
            end
        end)
    end

    local function onCharacterRemoving()
        if boxes[targetPlayer] then
            removeBox(boxes[targetPlayer])
            boxes[targetPlayer] = nil
        end
    end

    targetPlayer.CharacterAdded:Connect(onCharacterAdded)
    targetPlayer.CharacterRemoving:Connect(onCharacterRemoving)

    if targetPlayer.Character then
        onCharacterAdded(targetPlayer.Character)
    end
end

local function untrackPlayer(targetPlayer)
    if boxes[targetPlayer] then
        removeBox(boxes[targetPlayer])
        boxes[targetPlayer] = nil
    end
end

local function toggleESP()
    getgenv().TwoDBoxesEnabled = not getgenv().TwoDBoxesEnabled
    if not getgenv().TwoDBoxesEnabled then
        for _, box in pairs(boxes) do
            for _, line in ipairs(box) do
                line.Visible = false
            end
        end
    end
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        toggleESP()
    end
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then
        trackPlayer(plr)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= player then
        trackPlayer(plr)
    end
end)

Players.PlayerRemoving:Connect(untrackPlayer)
