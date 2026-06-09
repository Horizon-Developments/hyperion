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
    local ok, res = pcall(request,{
      Url = "https://catalog.roproxy.com/v1/search/items/details?Category=11&Subcategory=5&Keyword=".. HttpService:UrlEncode(v) .. "&Limit=30",
      Method = "GET"
    })
  if not ok or not res or res.StatusCode ~= 200 or not res.Body then
    
  end
  
local d = HttpService:JSONDecode(r.Body).data
if not d or not d[1] then return 2 end

local i = d[1]
return i.id .. "`5`0"
    
    
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