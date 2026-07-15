local args = ...
local Tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local Helpers = args.Helpers
local Assets = args.Assets

local Options = Obsidian.Options
local Toggles = Obsidian.Toggles

local HttpService = game:GetService("HttpService")
local saveFile = Assets(".saved_clipboard")

Tabs.clipboard = Window:AddTab("Clipboard", "clipboard")
local box = Tabs.clipboard:AddLeftGroupbox("Saved Clipboard")

local inputText = ""
local saveName = ""
local saves = {}

local function saveData()
  local ok, encoded = pcall(HttpService.JSONEncode, HttpService, saves)
  if not ok then return end
  pcall(writefile, saveFile, encoded)
end

local function loadData()
  local ok, raw = pcall(readfile, saveFile)
  if not ok or not raw or raw == "" then return end

  local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
  if not ok2 or not data then return end

  saves = data
end

local function refreshDropdown()
  local names = {}
  for name in pairs(saves) do table.insert(names, name) end
  Options["clipboard@select.dropdown"]:SetValues(names)
end

loadData()

box:AddInput("clipboard@text.input", {
  Text = "Input text to save",
  ClearTextOnFocus = false,
  Finished = false,
  Callback = function(v)
    inputText = v
  end
})

box:AddInput("clipboard@name.input", {
  Text = "Name of save",
  ClearTextOnFocus = false,
  Finished = false,
  Callback = function(v)
    saveName = v
  end
})

box:AddButton("clipboard@save.button", {
  Text = "Save",
  Func = function()
    if saveName == "" then return end
    saves[saveName] = inputText
    saveData()
    refreshDropdown()
  end
})

box:AddDropdown("clipboard@select.dropdown", {
  Values = {},
  Default = 1,
  Multi = false,
  Text = "Select save",
  Searchable = true,
})

box:AddButton("clipboard@copy.button", {
  Text = "Copy selected",
  Func = function()
    local selected = Options["clipboard@select.dropdown"].Value
    if not selected or not saves[selected] then return end
    setclipboard(saves[selected])
  end
})

box:AddButton("clipboard@delete.button", {
  Text = "Delete selected",
  Func = function()
    local selected = Options["clipboard@select.dropdown"].Value
    if not selected or not saves[selected] then return end
    saves[selected] = nil
    saveData()
    refreshDropdown()
  end
})

refreshDropdown()