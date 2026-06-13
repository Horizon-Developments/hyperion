local builder = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))()
if isfile("HYPBuild.lz4") then
  print("LOAD BUILD")
  local builder = autobuild.build("mybuild", {
    tp = true,
    offset = Vector3.new(0,0,0)
}, function(tool)
    return game.Players.LocalPlayer.Backpack:FindFirstChild(tool, true)
        or game.Players.LocalPlayer.Character:FindFirstChild(tool, true)
end)
  print("DONE")
else
  print("SAVE BUILD")
  autobuild.save("mybuild", {
    game.Players.LocalPlayer
  })
  print("DONE")
end