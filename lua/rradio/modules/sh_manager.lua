rRadio.StationManager = {
    Stations = {},
    CountryData = {},

    Initialize = function(self)
        -- Load station data files
        local files = file.Find("lua/rradio/core/stations/data_*.lua", "GAME")
        
        for _, f in ipairs(files) do
            local data = include("rradio/core/stations/" .. f)
            for countryCode, countryData in pairs(data) do
                self.CountryData[countryCode] = countryData
                
                -- Process stations
                for _, station in ipairs(countryData) do
                    if rRadio.Utils.ValidateURL(station.u) then
                        table.insert(self.Stations, {
                            name = station.n,
                            url = station.u,
                            country = countryCode
                        })
                    end
                end
            end
        end

        rRadio.CallHook("StationsInitialized", self.Stations)
    end,

    GetCountryStations = function(self, countryCode)
        local stations = {}
        for _, station in ipairs(self.Stations) do
            if station.country == countryCode then
                table.insert(stations, station)
            end
        end
        return stations
    end,

    GetAllCountries = function(self)
        return table.GetKeys(self.CountryData)
    end,

    FindStation = function(self, name, country)
        for _, station in ipairs(self.Stations) do
            if station.name == name and (not country or station.country == country) then
                return station
            end
        end
        return nil
    end
}

-- Initialize when the gamemode loads
hook.Add("Initialize", "rRadio_StationManager", function()
    rRadio.StationManager:Initialize()
end) 