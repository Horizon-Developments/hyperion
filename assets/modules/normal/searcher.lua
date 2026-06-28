local args = ...
local tabs   = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local assets = args.Assets
local Helpers = args.Helpers

tabs.searcher = Window:AddTab("Boombox & Gear Searcher", "search")
local box = tabs.searcher:AddLeftGroupbox("Searcher")

local AssetService = game:GetService("AssetService")
local HttpService  = game:GetService("HttpService")
local cache = {}

-- id -> display name maps
local bbNames = {}
local gearNames = {}

box:AddInput("boomboxSearch", {
    Text        = "Boombox Searcher",
    Tooltip     = "Search songs here!",
    Placeholder = "Enter keyword here",
    Callback    = function(keyword)
        if keyword == "" then return end
        local ok, raw = pcall(function()
            local params = Instance.new("AudioSearchParams")
            params.SearchKeyword = keyword
            return AssetService:SearchAudioAsync(params):GetCurrentPage()
        end)
        if not ok or not raw or #raw == 0 then
            Obsidian:Notify({ Title = "Not found", Description = "Nothing came up! Try another keyword.", Time = 3 })
            return
        end
        bbNames = {}
        local values = {}
        for _, result in ipairs(raw) do
            local id = tostring(result.Id)
            bbNames[id] = result.Title
            table.insert(values, id)
        end
        if cache.dropdownBB then
            cache.dropdownBB:SetValues(values)
            return
        end
        cache.dropdownBB = box:AddDropdown("boomboxResults", {
            Text    = "Boombox",
            Values  = values,
            Default = nil,
            Searchable = true,
            FormatDisplayValue = function(id)
                return bbNames[id] and (bbNames[id] .. " (" .. id .. ")") or id
            end,
            Callback = function(id)
                if not id then return end
                setclipboard(id)
                Obsidian:Notify({ Title = "Copied!", Description = "Copied ID: " .. id, Time = 3 })
                cache.dropdownBB:SetValue(nil)
            end
        })
    end
})

box:AddDivider()

box:AddInput("gearSearch", {
    Text        = "Gear Searcher",
    Tooltip     = "Search gears here!",
    Placeholder = "Enter keyword here",
    Callback    = function(keyword)
        if keyword == "" then return end
        local ok, res = pcall(request, {
            Url    = "https://catalog.roproxy.com/v1/search/items/details?Category=11&Subcategory=5&Keyword="
                     .. HttpService:UrlEncode(keyword) .. "&Limit=30",
            Method = "GET"
        })
        if not ok or not res or res.StatusCode ~= 200 or not res.Body then
            Helpers.log(ok, res)
            Obsidian:Notify({ Title = "Not found", Description = "An error happened and was logged.", Time = 3 })
            return
        end
        local data = HttpService:JSONDecode(res.Body).data
        if not data or not data[1] then
            Obsidian:Notify({ Title = "Not found", Description = "Nothing came up! Try another keyword.", Time = 3 })
            return
        end
        gearNames = {}
        local values = {}
        for _, item in ipairs(data) do
            local id = tostring(item.id)
            gearNames[id] = item.name
            table.insert(values, id)
        end
        if cache.dropdownG then
            cache.dropdownG:SetValues(values)
            return
        end
        cache.dropdownG = box:AddDropdown("gearResults", {
            Text    = "Gears",
            Values  = values,
            Default = nil,
            Searchable = true,
            FormatDisplayValue = function(id)
                return gearNames[id] and (gearNames[id] .. " (" .. id .. ")") or id
            end,
            Callback = function(id)
                if not id then return end
                setclipboard(id)
                Obsidian:Notify({ Title = "Copied!", Description = "Copied ID: " .. id, Time = 3 })
                cache.dropdownG:SetValue(nil)
            end
        })
    end
})

box:AddDivider()