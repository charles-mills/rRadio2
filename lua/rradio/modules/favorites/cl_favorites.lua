rRadio.Favorites = {
    Countries = {},
    Stations = {},
    
    Initialize = function(self)
        -- Create data directory if it doesn't exist
        if not file.Exists("rradio", "DATA") then
            file.CreateDir("rradio")
        end
        
        -- Load saved favorites
        local data = file.Read("rradio/favorites.txt", "DATA")
        if data then
            local saved = util.JSONToTable(data)
            if saved then
                self.Countries = saved.countries or {}
                self.Stations = saved.stations or {}
            end
        end
    end,
    
    Save = function(self)
        local data = util.TableToJSON({
            countries = self.Countries,
            stations = self.Stations
        }, true)
        file.Write("rradio/favorites.txt", data)
    end,
    
    ToggleCountry = function(self, country)
        local idx = table.HasValue(self.Countries, country)
        if idx then
            table.remove(self.Countries, idx)
        else
            -- Check favorites limit
            if #self.Countries >= rRadio.Config.UI.FavoritesLimit then
                return false
            end
            table.insert(self.Countries, country)
        end
        self:Save()
        return true
    end,
    
    ToggleStation = function(self, name, url)
        local idx = nil
        for i, station in ipairs(self.Stations) do
            if station.url == url then
                idx = i
                break
            end
        end
        
        if idx then
            table.remove(self.Stations, idx)
        else
            -- Check favorites limit
            if #self.Stations >= rRadio.Config.UI.FavoritesLimit then
                return false
            end
            table.insert(self.Stations, {
                name = name,
                url = url
            })
        end
        self:Save()
        return true
    end,
    
    IsCountryFavorite = function(self, country)
        return table.HasValue(self.Countries, country)
    end,
    
    IsStationFavorite = function(self, url)
        for _, station in ipairs(self.Stations) do
            if station.url == url then
                return true
            end
        end
        return false
    end
}

-- Initialize favorites system
rRadio.Favorites:Initialize() 