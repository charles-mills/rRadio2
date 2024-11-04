rRadio = rRadio or {}
rRadio.Config = {
    -- Entity Settings
    Entities = {
        DefaultRange = 1000,
        GoldenRange = 2000,
        VehicleRange = 500,
        MaxVolume = 100,
        SpawnLimit = 3, -- Per player
        Models = {
            default = "models/rammel/boombox.mdl",
            golden = "models/rammel/boombox.mdl",
            fallback = "models/props_lab/citizenradio.mdl"
        },
        -- Volume falloff settings (1.0 = linear, 2.0 = quadratic)
        Falloff = {
            Default = 1.0,
            Golden = 1.0,
            Vehicle = 2.0
        }
    },

    Network = {
        UpdateRate = 0.5, -- How often to sync station data
        StreamBufferSize = 8192,
        VehiclePositionUpdateRate = 0.1 -- How often to update vehicle radio positions (in seconds)
    },

    Permissions = {
        AdminGroups = {"superadmin", "admin"},
        AllowVehicleRadios = true,
        RestrictGoldenBoombox = true,
    },

    UI = {
        DefaultTheme = "dark",
        BrowserColumns = 3,
        FavoritesLimit = 50,
        UpdateRate = 0.03, -- ~30fps for UI updates
        AnimationSpeed = 0.2, -- Animation duration in seconds
        BaseWidth = 1920, -- Base resolution for scaling
        BaseHeight = 1080,
        MinWidth = 400,  -- Minimum window dimensions
        MinHeight = 600,
        Icons = {
            back = "rradio/icons/back.png",
            close = "rradio/icons/close.png",
            settings = "rradio/icons/settings.png",
            radio = "rradio/icons/radio.png",
            favorite = "rradio/icons/star.png",
            favorite_filled = "rradio/icons/star_filled.png",
            volume = "rradio/icons/volume.png",
            stop = "rradio/icons/stop.png"
        },
        Fonts = {
            Title = {
                font = "Roboto",
                size = 24,
                weight = 500
            },
            Item = {
                font = "Roboto",
                size = 18,
                weight = 400
            },
            Button = {
                font = "Roboto",
                size = 16,
                weight = 500
            }
        }
    },

    Cache = {
        MaxSize = 50 * 1024 * 1024, -- 50MB max cache size
        CleanupInterval = 300,       -- 5 minutes
        MaxCountries = 50,           -- Max countries to keep in memory
        MaxStationsPerCountry = 200, -- Max stations per country
        HotDataThreshold = 5,        -- Access count to consider data "hot"
        ColdDataThreshold = 300      -- Seconds before data is considered "cold"
    }
}

-- Add icons to download table
if SERVER then
    for _, path in pairs(rRadio.Config.UI.Icons) do
        resource.AddFile("materials/" .. path)
    end
end

rRadio.Hooks = {}

function rRadio.RegisterHook(hookName, identifier, func)
    rRadio.Hooks[hookName] = rRadio.Hooks[hookName] or {}
    rRadio.Hooks[hookName][identifier] = func
end

function rRadio.CallHook(hookName, ...)
    if not rRadio.Hooks[hookName] then return end
    
    local results = {}
    for _, func in pairs(rRadio.Hooks[hookName]) do
        local success, result = pcall(func, ...)
        if success and result ~= nil then
            table.insert(results, result)
        end
    end
    return results
end

rRadio.StationManager = {
    Countries = {},
    LoadedStations = {},

    Initialize = function(self)
        local files = file.Find("lua/rradio/core/stations/data_*.lua", "GAME")
        
        for _, f in ipairs(files) do
            local data = include("rradio/core/stations/" .. f)
            for countryCode, countryData in pairs(data) do
                self.Countries[countryCode] = countryData
                
                -- Allow other addons to modify station data
                rRadio.CallHook("StationsLoaded", countryCode, countryData)
            end
        end
    end,

    GetCountryStations = function(self, countryCode)
        return self.Countries[countryCode]
    end,

    GetAllCountries = function(self)
        local countries = {}
        for code, _ in pairs(self.Countries) do
            table.insert(countries, code)
        end
        return countries
    end,

    ValidateStation = function(self, url)
        -- Basic URL validation
        return url:match("^https?://") ~= nil
    end
}

if SERVER then
    CreateConVar("rradio_range_default", rRadio.Config.Entities.DefaultRange, FCVAR_ARCHIVE, "Default range for radio entities")
    CreateConVar("rradio_range_golden", rRadio.Config.Entities.GoldenRange, FCVAR_ARCHIVE, "Range for golden radio entities")
    CreateConVar("rradio_range_vehicle", rRadio.Config.Entities.VehicleRange, FCVAR_ARCHIVE, "Range for vehicle radios")
    CreateConVar("rradio_spawn_limit", rRadio.Config.Entities.SpawnLimit, FCVAR_ARCHIVE, "Maximum radios per player")
    CreateConVar("rradio_falloff_default", rRadio.Config.Entities.Falloff.Default, FCVAR_ARCHIVE, "Volume falloff for default radios (1.0 = linear, 2.0 = quadratic)")
    CreateConVar("rradio_falloff_golden", rRadio.Config.Entities.Falloff.Golden, FCVAR_ARCHIVE, "Volume falloff for golden radios (1.0 = linear, 2.0 = quadratic)")
    CreateConVar("rradio_falloff_vehicle", rRadio.Config.Entities.Falloff.Vehicle, FCVAR_ARCHIVE, "Volume falloff for vehicle radios (1.0 = linear, 2.0 = quadratic)")
end

rRadio.RegisterHook("StationsLoaded", "Core", function(countryCode, stations)
    print("[rRadio] Loaded " .. #stations .. " stations for " .. countryCode)
end)

rRadio.RegisterHook("PrePlayStation", "Core", function(ent, url)
    return rRadio.StationManager:ValidateStation(url)
end)

hook.Add("Initialize", "rRadio_Init", function()
    rRadio.StationManager:Initialize()
end)

-- Add scaling utilities
rRadio.UI = rRadio.UI or {}

function rRadio.UI.Scale(value)
    local screenWidth = ScrW()
    local screenHeight = ScrH()
    local scaleX = screenWidth / rRadio.Config.UI.BaseWidth
    local scaleY = screenHeight / rRadio.Config.UI.BaseHeight
    local scale = math.min(scaleX, scaleY)
    
    return math.Round(value * scale)
end

function rRadio.UI.ScaleW(width)
    return math.max(rRadio.UI.Scale(width), rRadio.Config.UI.MinWidth)
end

function rRadio.UI.ScaleH(height)
    return math.max(rRadio.UI.Scale(height), rRadio.Config.UI.MinHeight)
end

function rRadio.UI.ScaleFont(name, size)
    local scaledSize = rRadio.UI.Scale(size)
    local fontName = "rRadio_" .. name .. "_" .. scaledSize
    
    if not _G[fontName] then
        surface.CreateFont(fontName, {
            font = "Roboto",
            size = scaledSize,
            weight = 500,
            antialias = true,
            extended = true
        })
    end
    
    return fontName
end 