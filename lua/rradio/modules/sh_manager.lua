rRadio.StationManager = {
    -- Primary data storage
    Data = {
        Countries = {},      -- {code = {name = name, loaded = bool}}
        Stations = {},       -- {countryCode = {stations}}
        URLIndex = {},       -- {url = stationReference}
        NameIndex = {},      -- {name = {countryCode = stationReference}}
    },

    -- Cache management
    Cache = {
        Size = 0,
        LastCleanup = 0,
        AccessCounts = {},   -- {countryCode = count}
        LastAccessed = {},   -- {countryCode = time}
        LoadedData = {},     -- Track loaded data size
    },

    Initialize = function(self)
        if SERVER then return end
        print("[rRadio] Initializing station manager")

        -- Load country list only (lightweight)
        self:LoadCountryList()
        
        -- Debug print all loaded countries
        for code, _ in pairs(self.Data.Countries) do
            print("[rRadio] Loaded country: " .. code)
        end

        -- Set up cache cleanup timer
        timer.Create("rRadio_CacheCleanup", rRadio.Config.Cache.CleanupInterval, 0, function()
            self:CleanupCache()
        end)
    end,

    LoadCountryList = function(self)
        local files = file.Find("lua/rradio/modules/stations/data_*.lua", "GAME")
        print("[rRadio] Found " .. #files .. " station files")
        
        for _, f in ipairs(files) do
            print("[rRadio] Loading file: " .. f)
            local data = include("rradio/modules/stations/" .. f)
            if data then
                for countryCode, countryData in pairs(data) do
                    self.Data.Countries[countryCode] = {
                        name = countryCode,
                        loaded = false
                    }
                    print("[rRadio] Added country: " .. countryCode)
                end
            else
                print("[rRadio] Failed to load file: " .. f)
            end
        end
        
        print("[rRadio] Loaded " .. table.Count(self.Data.Countries) .. " countries")
    end,

    LoadCountryStations = function(self, countryCode)
        print("[rRadio] Loading stations for " .. countryCode)
        
        if self.Data.Stations[countryCode] then
            print("[rRadio] Already loaded, returning cached data")
            return true
        end

        -- Load station data
        local files = file.Find("lua/rradio/modules/stations/data_*.lua", "GAME")
        for _, f in ipairs(files) do
            local data = include("rradio/modules/stations/" .. f)
            if data and data[countryCode] then
                print("[rRadio] Found stations in file: " .. f)
                
                -- Process and index stations
                self.Data.Stations[countryCode] = {}
                
                for _, station in ipairs(data[countryCode]) do
                    if station.n and station.u and rRadio.Utils.ValidateURL(station.u) then
                        -- Create single station instance
                        local stationRef = {
                            name = station.n,
                            url = station.u,
                            country = countryCode
                        }

                        -- Add to main storage
                        table.insert(self.Data.Stations[countryCode], stationRef)

                        -- Index by URL (unique)
                        self.Data.URLIndex[station.u] = stationRef

                        -- Index by name (can have multiple per country)
                        self.Data.NameIndex[station.n] = self.Data.NameIndex[station.n] or {}
                        self.Data.NameIndex[station.n][countryCode] = stationRef
                    end
                end

                print("[rRadio] Loaded " .. #self.Data.Stations[countryCode] .. " stations")
                return true
            end
        end
        
        print("[rRadio] No stations found for " .. countryCode)
        return false
    end,

    GetCountryStations = function(self, countryCode)
        if not self.Data.Stations[countryCode] then
            if not self:LoadCountryStations(countryCode) then
                return {}
            end
        end

        -- Update access metrics
        self.Cache.LastAccessed[countryCode] = CurTime()
        self.Cache.AccessCounts[countryCode] = (self.Cache.AccessCounts[countryCode] or 0) + 1

        return self.Data.Stations[countryCode] or {}
    end,

    CleanupCache = function(self)
        local currentTime = CurTime()
        local totalSize = 0
        local candidates = {}

        -- Identify cleanup candidates
        for countryCode, lastAccessed in pairs(self.Cache.LastAccessed) do
            local timeSinceAccess = currentTime - lastAccessed
            local accessCount = self.Cache.AccessCounts[countryCode] or 0
            
            -- Skip "hot" data
            if accessCount > rRadio.Config.Cache.HotDataThreshold then
                continue
            end

            -- Add to candidates if "cold"
            if timeSinceAccess > rRadio.Config.Cache.ColdDataThreshold then
                table.insert(candidates, {
                    code = countryCode,
                    score = timeSinceAccess / (accessCount + 1)
                })
            end

            totalSize = totalSize + (self.Cache.LoadedData[countryCode] or 0)
        end

        -- Clean if necessary
        if totalSize > rRadio.Config.Cache.MaxSize then
            table.sort(candidates, function(a, b)
                return a.score > b.score
            end)

            for _, candidate in ipairs(candidates) do
                if totalSize <= rRadio.Config.Cache.MaxSize then break end
                
                -- Clear country data
                local countrySize = self.Cache.LoadedData[candidate.code] or 0
                self:ClearCountryData(candidate.code)
                totalSize = totalSize - countrySize
            end
        end

        self.Cache.LastCleanup = currentTime
    end,

    ClearCountryData = function(self, countryCode)
        if not self.Data.Stations[countryCode] then return end

        -- Remove from indices
        for _, station in ipairs(self.Data.Stations[countryCode]) do
            self.Data.URLIndex[station.url] = nil
            if self.Data.NameIndex[station.name] then
                self.Data.NameIndex[station.name][countryCode] = nil
            end
        end

        -- Clear main data
        self.Data.Stations[countryCode] = nil
        self.Cache.LoadedData[countryCode] = nil
        self.Cache.LastAccessed[countryCode] = nil
        self.Cache.AccessCounts[countryCode] = nil
    end,

    EstimateDataSize = function(self, countryCode)
        local stations = self.Data.Stations[countryCode]
        if not stations then return 0 end

        local size = 0
        for _, station in ipairs(stations) do
            -- Estimate size of station data (name + url + references)
            size = size + #station.name + #station.url + 100
        end
        return size
    end,

    GetAllCountries = function(self)
        local countries = {}
        for code, _ in pairs(self.Data.Countries) do
            table.insert(countries, code)
        end
        table.sort(countries)
        print("[rRadio] GetAllCountries returning " .. #countries .. " countries")
        return countries
    end
}

hook.Add("Initialize", "rRadio_StationManager", function()
    rRadio.StationManager:Initialize()
end) 