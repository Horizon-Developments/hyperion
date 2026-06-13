local args = ...

local tabs   = args.Tabs
local Window = args.Window
local WindUI = args.WindUI
local assets = args.Assets
local Helpers = args.Helpers

tabs.autobuild = Window:Tab({
    Title = "Autobuild",
    Icon  = "blocks",
})

local lib      = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))(...)
local players  = Helpers.services.players
local localplr = players.LocalPlayer
local tab      = tabs.autobuild
local SAVE_DIR = assets("Builds")

local cfg = {
  historymax = 300,
  resizewait = 0.4,
  wbs        = false,
  offset     = Vector3.new(0, 0, 0),
}

tab:Divider()

local RunService = game:GetService("RunService")

local enabled = false
local conn

local function update()
    if conn then conn:Disconnect() end
    conn = RunService.Heartbeat:Connect(function()
        if not enabled then return end

        for _, obj in ipairs(workspace.Bricks:GetChildren()) do
            if obj:IsA("Model") and #obj:GetChildren() > 0 then
                -- example operation (replace with your logic)
                obj:PivotTo(obj:GetPivot())
            end
        end
    end)
end

Tab:Toggle({
    Title = "Live Update Bricks",
    Desc = "keeps models processed every frame",
    Icon = "bird",
    Type = "Checkbox",
    Value = false,

    Callback = function(state)
        enabled = state
        if state then
            update()
        elseif conn then
            conn:Disconnect()
            conn = nil
        end
    end
})





















