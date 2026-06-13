local builder = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))()
if isfile("HYPBuild.lz4") then
  print("LOAD BUILD")
  builder.auto_build("MyBase.lz4", {resizewait = 0.1}, function(tool) 
    return game.Players.LocalPlayer.Backpack:FindFirstChild(tool_type) or game.Players.LocalPlayer.Character:FindFirstChild(tool_type, true)
  end):start()
  print("DONE")
else
  print("SAVE BUILD")
  builder.save_build("HYPBuild", {game.Players.LocalPlayer})
  print("DONE")
end