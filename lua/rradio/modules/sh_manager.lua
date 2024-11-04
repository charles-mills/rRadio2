rRadio.StationManager = {
    -- Primary data storage
    Data = {
        Countries = {},      -- {code = {name = name, loaded = bool}}
        Stations = {},       -- {countryCode = {stations}}
        URLIndex = {},       -- {url = stationReference}
        NameIndex = {},      -- {name = {countryCode = stationReference}}
    },

    Initialize = function(self)
        if SERVER then return end
        print("[rRadio] Initializing station manager")

        -- Load station data files
        local files = file.Find("lua/rradio/modules/stations/data_*.lua", "GAME")
        print("[rRadio] Found " .. #files .. " station files")
        
        for _, f in ipairs(files) do
            local data = include("rradio/modules/stations/" .. f)
            if data then
                for countryCode, countryData in pairs(data) do
                    -- Store country data
                    self.Data.Countries[countryCode] = {
                        name = countryCode,
                        loaded = false
                    }
                    
                    -- Pre-load stations
                    self.Data.Stations[countryCode] = {}
                    for _, station in ipairs(countryData) do
                        if station.n and station.u then
                            local stationRef = {
                                name = station.n,
                                url = station.u,
                                country = countryCode
                            }
                            table.insert(self.Data.Stations[countryCode], stationRef)
                            
                            -- Index by URL
                            self.Data.URLIndex[station.u] = stationRef
                            
                            -- Index by name
                            self.Data.NameIndex[station.n] = self.Data.NameIndex[station.n] or {}
                            self.Data.NameIndex[station.n][countryCode] = stationRef
                        end
                    end
                end
            end
        end
        
        print("[rRadio] Loaded " .. table.Count(self.Data.Countries) .. " countries")
        print("[rRadio] Loaded " .. table.Count(self.Data.Stations) .. " country station lists")
    end,

    GetCountryStations = function(self, countryCode)
        print("[rRadio] StationManager: Getting stations for", countryCode)
        
        local stations = self.Data.Stations[countryCode]
        if not stations then
            print("[rRadio] Error: No stations found for", countryCode)
            return {}
        end
        
        print("[rRadio] StationManager: Found", #stations, "stations")
        for i, station in ipairs(stations) do
            print(string.format("[rRadio] Station %d: %s - %s", i, station.name, station.url))
        end
        
        return stations
    end,

    GetAllCountries = function(self)
        return table.GetKeys(self.Data.Countries)
    end,

    FindStation = function(self, name, country)
        if country then
            return self.Data.NameIndex[name] and self.Data.NameIndex[name][country]
        end
        return self.Data.URLIndex[name]
    end
}

hook.Add("Initialize", "rRadio_StationManager", function()
    rRadio.StationManager:Initialize()
end) 