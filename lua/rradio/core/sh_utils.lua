rRadio.Utils = {
    -- String formatting
    FormatName = function(str)
        -- Remove underscores and convert to title case
        str = str:gsub("_", " ")
        return str:gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
    end,

    -- String utilities
    FormatTime = function(seconds)
        return string.format("%02d:%02d", math.floor(seconds/60), seconds%60)
    end,

    -- Table utilities
    MergeStations = function(t1, t2)
        local result = table.Copy(t1)
        for _, station in ipairs(t2) do
            table.insert(result, station)
        end
        return result
    end,

    -- Validation utilities
    ValidateURL = function(url)
        return url:match("^https?://") ~= nil
    end,

    -- Network utilities
    CompressData = function(data)
        return util.Compress(util.TableToJSON(data))
    end,

    DecompressData = function(data)
        return util.JSONToTable(util.Decompress(data))
    end,

    -- Entity utilities
    GetRange = function(ent)
        if not IsValid(ent) then return 0 end
        return ent:GetGolden() and GetConVar("rradio_range_golden"):GetInt() 
                                or GetConVar("rradio_range_default"):GetInt()
    end,

    -- Safe material loading
    GetIcon = function(name)
        if not rRadio.Config.UI.Icons[name] then
            print("[rRadio] Warning: Missing icon configuration for " .. name)
            return Material("icon16/error.png")
        end
        
        local mat = Material(rRadio.Config.UI.Icons[name])
        if not mat or mat:IsError() then
            print("[rRadio] Warning: Failed to load icon " .. rRadio.Config.UI.Icons[name])
            return Material("icon16/error.png")
        end
        
        return mat
    end,

    -- Format country names
    FormatCountryName = function(countryCode)
        -- Replace underscores with spaces
        local name = countryCode:gsub("_", " ")
        
        -- Title case each word
        name = name:gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
        
        -- Special cases for country names
        local specialCases = {
            ["Uk"] = "UK",
            ["Usa"] = "USA",
            ["Uae"] = "UAE",
            ["Dj"] = "DJ",
        }
        
        -- Apply special cases
        for pattern, replacement in pairs(specialCases) do
            name = name:gsub(pattern, replacement)
        end
        
        return name
    end,

    -- Color interpolation
    LerpColor = function(fraction, from, to)
        return Color(
            Lerp(fraction, from.r, to.r),
            Lerp(fraction, from.g, to.g),
            Lerp(fraction, from.b, to.b),
            Lerp(fraction, from.a or 255, to.a or 255)
        )
    end
} 