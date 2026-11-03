-- SurvivorTasks.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local SurvivorTasks = {}

-- Initialize the survivor tasks
function SurvivorTasks:Init()
    -- Set up remote events
    self:SetupRemoteEvents()
end

-- Complete a task
function SurvivorTasks:CompleteTask(taskObject)
    -- Notify the server that a task has been completed
    local remoteEvent = ReplicatedStorage:FindFirstChild("CompleteTask")
    if remoteEvent then
        remoteEvent:FireServer()
    end

    -- Visual feedback for task completion
    taskObject.Task.BrickColor = BrickColor.new("Lime green")
end

-- Set up remote events
function SurvivorTasks:SetupRemoteEvents()
    local remoteEvents = {
        "TaskCompleted"
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
function SurvivorTasks:HandleRemoteEvent(eventName, ...)
    if eventName == "TaskCompleted" then
        local playerName, tasksCompleted = ...
        if playerName == Player.Name then
            self:OnTaskCompleted(tasksCompleted)
        end
    end
end

-- Handle task completed
function SurvivorTasks:OnTaskCompleted(tasksCompleted)
    -- Implement visual or audio feedback for task completion
    print("Task completed! Total tasks completed: " .. tasksCompleted)
end

-- Initialize the survivor tasks
SurvivorTasks:Init()

return SurvivorTasks