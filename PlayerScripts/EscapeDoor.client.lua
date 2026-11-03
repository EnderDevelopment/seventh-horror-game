-- EscapeDoor.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local EscapeDoor = {}

-- Initialize the escape door
function EscapeDoor:Init()
    -- Set up remote events
    self:SetupRemoteEvents()
end

-- Open the escape door
function EscapeDoor:OpenEscapeDoor()
    -- Notify the server that the escape door has been opened
    local remoteEvent = ReplicatedStorage:FindFirstChild("EscapeDoorOpened")
    if remoteEvent then
        remoteEvent:FireServer()
    end
end

-- Set up remote events
function EscapeDoor:SetupRemoteEvents()
    local remoteEvents = {
        "OpenEscapeDoor"
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
function EscapeDoor:HandleRemoteEvent(eventName, ...)
    if eventName == "OpenEscapeDoor" then
        self:OnOpenEscapeDoor()
    end
end

-- Handle opening of the escape door
function EscapeDoor:OnOpenEscapeDoor()
    -- Implement visual or audio feedback for the escape door opening
    print("The escape door has been opened!")
end

-- Initialize the escape door
EscapeDoor:Init()

return EscapeDoor