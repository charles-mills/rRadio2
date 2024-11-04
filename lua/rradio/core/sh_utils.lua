rRadio.Utils = {
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
    end
} 