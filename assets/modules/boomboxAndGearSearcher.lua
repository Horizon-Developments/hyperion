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
local HttpService = game:GetService("HttpService")
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
    if (keyword == "") then return end
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
tab:Input({
  Title = "Gear searcher",
  Desc = "Search gears here!",
  Value = "",
  InputIcon = "settings",
  Type = "Input",
  Placeholder = "Enter keyword here",
  Callback = function(keyword)
    print(pcall(function()
    local ok, res = pcall(request,{
      Url = "https://catalog.roproxy.com/v1/search/items/details?Category=11&Subcategory=5&Keyword=".. HttpService:UrlEncode(v) .. "&Limit=30",
      Method = "GET"
    })
    if not ok or not res or res.StatusCode ~= 200 or not res.Body then
      print("[HYPERION] ", ok, res, res.StatusCode, res.Body, err)
      WindUI:Notify({ Title = "Not found", Content = "An error happend and was logged.", Duration = 3 })
      return
    end
    local data = HttpService:JSONDecode(res.Body).data
    
    if (not data or not data[1]) then
      print("[HYPERION] ", ok, res, res.StatusCode, res.Body, err)
      WindUI:Notify({ Title = "Not found", Content = "Nothing came up! try using another keyword.", Duration = 3 })
    end
    print(HttpService:JSONDecode(data))
    if (cache.dropdownG) then cache.dropdownG:Destroy() end
    cache.dropdownG = tab:Dropdown({
      Title = "Copy here",
      Desc = "",
      Values = data,
      Value = nil,
      AllowNone = true,
      Callback = function(option) 
        if (option == nil) then return end
        setclipboard(tostring(option.id))
        WindUI:Notify({ Title = "Copied!", Content = "Copied to your clipboard.", Duration = 3 })
        Dropdown:Select(nil)
      end
    })
  end)) 
  end
})