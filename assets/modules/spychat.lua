local Players = game:GetService("Players")
local tcs = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer
local channel = tcs:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local function getTeamColor(userId)
  local player = Players:GetPlayerByUserId(userId)
  if player and player.Team then
    return player.Team.TeamColor.Color
  end
  return Color3.fromRGB(255, 255, 255)
end

local function colorToHex(c)
  return string.format("%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

local existing = getcallbackvalue and getcallbackvalue(channel, "OnIncomingMessage")

channel.OnIncomingMessage = function(m)
  local tcmp = existing and existing(m) or Instance.new("TextChatMessageProperties")
  
  if m.TextSource then
    if m.Text and m.Text:sub(1, 3) == "hx." and m.TextSource.UserId == LocalPlayer.UserId then
      task.spawn(handler, m)
      tcmp.Text = " "
      tcmp.PrefixText = ""
    else
      local color = getTeamColor(m.TextSource.UserId
        
        
        
        
        
        
        
      local hex = colorToHex(color)
      tcmp.PrefixText = string.format('<font color="#%s">%s</font>', hex, m.PrefixText)
    end
  end
  
  return tcmp
end