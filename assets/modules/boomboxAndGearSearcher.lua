local args = ...

local tabs = args.Tabs
-- tabs register or use tabs here.
local Window = args.Window
-- wind ui window used by Hyperion
local WindUI = args.WindUI
-- WindUi 
local assets = args.Assets
-- store files in assets("your folder") (don't forget to run makefolder though)


tabs.searcher = Window:Tab({
  Title = "boombox and gear searcher",
  Icon = "search"
})
local AssetService = game:GetService("AssetService")
local tab = tabs.searcher
local cache = {}

tab:Input({
  Title = "Boombox searcher",
  Desc = "Search songs here!",
  Value = "",
  InputIcon = "music",
  Type = "Input",
  Placeholder = "Enter keyword here",
  Callback = function(keyword) 
    local params = Instance.new("AudioSearchParams")
    params.SearchKeyword = keyword
    local results = AssetService:SearchAudioAsync(params):GetCurrentPage() 
    if (#results <= 0) then
      WindUI:Notify({ Title = "Not found", Content = "Nothing came up! try using another keyword.", Duration = 3 })
      return
    end
    if (cache.dropdownBB) then cache.dropdownBB:Destroy() end
    cache.dropdownBB = tab:Dropdown({
      Title = "Copy here",
      Desc = "",
      Values = results,
      Value = nil,
      AllowNone = true,
      Callback = function(option) 
        if (option == nil) then return end
        setclipboard(tostring(option.Id))
        WindUI:Notify({ Title = "Copied!", Content = "Copied to your clipboard.", Duration = 3 })
        Dropdown:Select(nil)
      end
    })
  end
})
