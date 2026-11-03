-- GameManager.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameManager = {}

-- Game state
GameManager.GameState = {
    Players = {},
    Monster = nil,
    TasksCompleted = 0,
    TotalTasks = 6,
    GameStarted = false,
    GameEnded = false
}

-- Initialize the game
function GameManager:Init()
    -- Set up player added/removed events
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoved(player)
    end)

    -- Set up remote events
    self:SetupRemoteEvents()
end

-- Handle player joining
function GameManager:OnPlayerAdded(player)
    -- Initialize player data
    self.GameState.Players[player] = {
        IsMonster = false,
        TasksCompleted = 0
    }

    -- If the game has started, assign a role immediately
    if self.GameState.GameStarted then
        self:AssignRoles()
    end
end

-- Handle player leaving
function GameManager:OnPlayerRemoved(player)
    -- Remove player data
    self.GameState.Players[player] = nil

    -- If the monster leaves, end the game
    if player == self.GameState.Monster then
        self:EndGame(false)
    end
end

-- Start the game
function GameManager:StartGame()
    if self.GameState.GameStarted then return end

    self.GameState.GameStarted = true
    self:AssignRoles()

    -- Notify clients that the game has started
    self:NotifyClients("GameStarted")
end

-- Assign roles to players
function GameManager:AssignRoles()
    local players = Players:GetPlayers()
    if #players < 2 then return end

    -- Reset all players to survivors
    for _, player in ipairs(players) do
        self.GameState.Players[player].IsMonster = false
    end

    -- Randomly select a monster
    local monsterIndex = math.random(1, #players)
    local monster = players[monsterIndex]
    self.GameState.Players[monster].IsMonster = true
    self.GameState.Monster = monster

    -- Notify clients about their roles
    for _, player in ipairs(players) do
        local isMonster = player == monster
        self:NotifyClient(player, "RoleAssigned", isMonster)
    end
end

-- Complete a task
function GameManager:CompleteTask(player)
    if not self.GameState.GameStarted or self.GameState.GameEnded then return end

    local playerData = self.GameState.Players[player]
    if not playerData or playerData.IsMonster then return end

    playerData.TasksCompleted = playerData.TasksCompleted + 1
    self.GameState.TasksCompleted = self.GameState.TasksCompleted + 1

    -- Check if all tasks are completed
    if self.GameState.TasksCompleted >= self.GameState.TotalTasks then
        self:OpenEscapeDoor()
    end

    -- Notify clients about the task completion
    self:NotifyClients("TaskCompleted", player.Name, playerData.TasksCompleted)
end

-- Open the escape door
function GameManager:OpenEscapeDoor()
    if self.GameState.GameEnded then return end

    -- Notify clients to open the escape door
    self:NotifyClients("OpenEscapeDoor")
end

-- End the game
function GameManager:EndGame(survivorsWin)
    if self.GameState.GameEnded then return end

    self.GameState.GameEnded = true

    -- Notify clients about the game ending
    self:NotifyClients("GameEnded", survivorsWin)

    -- Reset the game state
    self.GameState.TasksCompleted = 0
    self.GameState.GameStarted = false
    self.GameState.Monster = nil

    -- Reset player data
    for _, player in ipairs(Players:GetPlayers()) do
        self.GameState.Players[player].TasksCompleted = 0
    end
end

-- Set up remote events
function GameManager:SetupRemoteEvents()
    local remoteEvents = {
        "StartGame",
        "CompleteTask",
        "EscapeDoorOpened",
        "MonsterKilled"
    }

    for _, eventName in ipairs(remoteEvents) do
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = ReplicatedStorage

        remoteEvent.OnServerEvent:Connect(function(player, ...)
            self:HandleRemoteEvent(eventName, player, ...)
        end)
    end
end

-- Handle remote events
function GameManager:HandleRemoteEvent(eventName, player, ...)
    if eventName == "StartGame" then
        self:StartGame()
    elseif eventName == "CompleteTask" then
        self:CompleteTask(player)
    elseif eventName == "EscapeDoorOpened" then
        self:EndGame(true)
    elseif eventName == "MonsterKilled" then
        self:EndGame(false)
    end
end

-- Notify all clients
function GameManager:NotifyClients(eventName, ...)
    local remoteEvent = ReplicatedStorage:FindFirstChild(eventName)
    if remoteEvent then
        remoteEvent:FireAllClients(...)
    end
end

-- Notify a specific client
function GameManager:NotifyClient(player, eventName, ...)
    local remoteEvent = ReplicatedStorage:FindFirstChild(eventName)
    if remoteEvent then
        remoteEvent:FireClient(player, ...)
    end
end

-- Initialize the game manager
GameManager:Init()

return GameManager