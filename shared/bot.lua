--[[
  Hyperion Project
  Copyright (c) 2026 Horizon-Developments
  All rights reserved.
  Repository:
  https://github.com/Horizon-Developments/hyperion
  License:
  https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md
]]
local a={...}if not a[1]or not a[2]then error("Malformed script")end;local b=a[1]local c=a[2]local d=game:GetService("HttpService")local e,f=pcall(WebSocket.connect,b)if not e then error("[bot] WebSocket connection failed: "..tostring(f))end;f.OnMessage:Connect(function(g)if g=="Authorization"then local e,h=pcall(function()f:Send(d:JSONEncode({client_password=c}))end)if not e then warn("[bot] Failed to send auth: "..tostring(h))f:Close()end elseif g=="HeartBeat"then pcall(f.Send,f,"HeartBeat")else local i,h=loadstring(g)if not i then warn("[bot] loadstring failed: "..tostring(h))return end;local e,h=pcall(i)if not e then warn("[bot] script error: "..tostring(h))end end end)f.OnClose:Connect(function()warn("[bot] disconnected from relay")end)