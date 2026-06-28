local fn, err = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/hyperion.lua"))
print("[LOADER]: " ,fn, err, fn())
if not ok then
  print("[LOADER]: Report this error in our discord server: discord.gg/xbkVzSxDBy\n screenshot the error")
  game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
end