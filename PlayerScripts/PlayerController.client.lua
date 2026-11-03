-- PlayerController.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local PlayerController = {}

-- Player state
PlayerController.PlayerState = {
    IsMonster = false,
    TasksCompleted = 0,
    GameStarted = false,
    GameEnded = false
}

-- Initialize the player controller
function PlayerController:Init()
    -- Set up remote events
    self:SetupRemoteEvents()

    -- Set up character events
    Player.CharacterAdded:Connect(function(character)
        Character = character
        self:OnCharacterAdded(character)
    end)

    if Character then
        self:OnCharacterAdded(Character)
    end

    -- Set up input events
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        self:OnInputBegan(input, gameProcessed)
    end)
end

-- Handle character added
function PlayerController:OnCharacterAdded(character)
    -- Add any character-specific setup here
end

-- Handle input began
function PlayerController:OnInputBegan(input, gameProcessed)
    if gameProcessed then return end

    -- Handle input for both monster and survivors
    if input.KeyCode == Enum.KeyCode.E then
        self:Interact()
    end

    -- Handle monster-specific input
    if self.PlayerState.IsMonster then
        if input.KeyCode == Enum.KeyCode.Q then
            self:UseSpecialAbility()
        end
    end
end

-- Interact with objects
function PlayerController:Interact()
    if not self.PlayerState.GameStarted or self.PlayerState.GameEnded then return end

    -- Raycast to find objects to interact with
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(
        Character.HumanoidRootPart.Position,
        Character.HumanoidRootPart.CFrame.LookVector * 10,
        raycastParams
    )

    if raycastResult then
        local object = raycastResult.Instance

        -- Handle interaction with tasks
        if object:IsA("Model") and object:FindFirstChild("Task") then
            self:CompleteTask(object)
        end

        -- Handle interaction with the escape door
        if object.Name == "EscapeDoor" then
            self:OpenEscapeDoor()
        end
    end
end

-- Complete a task
function PlayerController:CompleteTask(taskObject)
    if self.PlayerState.IsMonster then return end

    -- Notify the server that a task has been completed
    local remoteEvent = ReplicatedStorage:FindFirstChild("CompleteTask")
    if remoteEvent then
        remoteEvent:FireServer()
    end

    -- Visual feedback for task completion
    taskObject.Task.BrickColor = BrickColor.new("Lime green")
end

-- Open the escape door
function PlayerController:OpenEscapeDoor()
    if self.PlayerState.IsMonster then return end

    -- Notify the server that the escape door has been opened
    local remoteEvent = ReplicatedStorage:FindFirstChild("EscapeDoorOpened")
    if remoteEvent then
        remoteEvent:FireServer()
    end
end

-- Use special ability (monster only)
function PlayerController:UseSpecialAbility()
    if not self.PlayerState.IsMonster then return end

    -- Implement monster's special ability here
    print("Monster used special ability!")
end

-- Set up remote events
function PlayerController:SetupRemoteEvents()
    local remoteEvents = {
        "GameStarted",
        "RoleAssigned",
        "TaskCompleted",
        "OpenEscapeDoor",
        "GameEnded"
    }

    for _, eventName in ipairs(remoteEvents) do
        local remoteEvent = ReplicatedStorage:FindFirstChild(eventName)
        if remoteEvent then
            remoteEvent.OnClientEvent:Connect(function(...)
                self:HandleRemoteEvent(eventName, ...)
            end)
        end
    end
end

-- Handle remote events
function PlayerController:HandleRemoteEvent(eventName, ...)
    if eventName == "GameStarted" then
        self.PlayerState.GameStarted = true
    elseif eventName == "RoleAssigned" then
        local isMonster = ...
        self.PlayerState.IsMonster = isMonster
        self:OnRoleAssigned(isMonster)
    elseif eventName == "TaskCompleted" then
        local playerName, tasksCompleted = ...
        if playerName == Player.Name then
            self.PlayerState.TasksCompleted = tasksCompleted
        end
    elseif eventName == "OpenEscapeDoor" then
        self:OnOpenEscapeDoor()
    elseif eventName == "GameEnded" then
        local survivorsWin = ...
        self.PlayerState.GameEnded = true
        self:OnGameEnded(survivorsWin)
    end
end

-- Handle role assignment
function PlayerController:OnRoleAssigned(isMonster)
    if isMonster then
        print("You are the monster!")
    else
        print("You are a survivor!")
    end
end

-- Handle opening of the escape door
function PlayerController:OnOpenEscapeDoor()
    print("The escape door has been opened!")
end

-- Handle game ended
function PlayerController:OnGameEnded(survivorsWin)
    if survivorsWin then
        print("Survivors win!")
    else
        print("Monster wins!")
    end
end

-- Initialize the player controller
PlayerController:Init()