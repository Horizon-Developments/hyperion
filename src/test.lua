local builder = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))()
if isfile("HYPBuild.lz4") then
  print("LOAD BUILD")
  autobuild.save("mybuild", {
    game.Players.LocalPlayer
})
  print("DONE")
else
  print("SAVE BUILD")
  autobuild.save("mybuild", {
    game.Players.LocalPlayer
  })
  print("DONE")
end