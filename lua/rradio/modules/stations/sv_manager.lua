-- Server-side station management
rRadio.ActiveStations = {
    -- Store active stations
    Stations = {},
    
    -- Network strings
    Initialize = function(self)
        util.AddNetworkString("rRadio_SelectStation")
        util.AddNetworkString("rRadio_StreamUpdate")
        
        -- Register hooks
        hook.Add("PlayerInitialSpawn", "rRadio_SyncStations", function(ply)
            timer.Simple(1, function()
                if IsValid(ply) then
                    self:SyncToPlayer(ply)
                end
            end)
        end)
        
        hook.Add("EntityRemoved", "rRadio_CleanupStation", function(ent)
            if IsValid(ent) and (ent:GetClass() == "rradio_boombox" or ent:IsVehicle()) then
                self:RemoveStation(ent)
            end
        end)
        
        print("[rRadio] Server-side station manager initialized")
    end,
    
    -- Set or update a station
    SetStation = function(self, ent, data)
        print(string.format("[rRadio] SetStation called - Entity: %s, Name: %s, URL: %s", 
            tostring(ent), data.name, data.url))
        
        if not IsValid(ent) then 
            print("[rRadio] SetStation failed - Invalid entity")
            return false 
        end
        if not data.name or not data.url then 
            print("[rRadio] SetStation failed - Invalid data")
            return false 
        end
        
        local entIndex = ent:EntIndex()
        
        -- Store station data
        self.Stations[entIndex] = {
            entity = ent,
            name = data.name,
            url = data.url,
            volume = data.volume or 100,
            timestamp = CurTime(),
            type = data.type or "entity"
        }
        
        print(string.format("[rRadio] Station stored for entity %d", entIndex))
        
        -- Notify nearby players
        net.Start("rRadio_StreamUpdate")
            net.WriteEntity(ent)
            net.WriteBool(false)  -- not stopping
            net.WriteString(data.name)
            net.WriteString(data.url)
            net.WriteFloat(data.volume or 100)
        net.SendPVS(ent:GetPos())
        
        print(string.format("[rRadio] Stream update sent to PVS for entity %d", entIndex))
        return true
    end,
    
    -- Remove a station
    RemoveStation = function(self, ent)
        if not IsValid(ent) then return false end
        
        local entIndex = ent:EntIndex()
        if not self.Stations[entIndex] then return false end
        
        -- Remove station data
        self.Stations[entIndex] = nil
        
        -- Notify nearby players
        net.Start("rRadio_StreamUpdate")
            net.WriteEntity(ent)
            net.WriteBool(true)  -- stopping
        net.SendPVS(ent:GetPos())
        
        print(string.format("[rRadio] Removed station for entity %d", entIndex))
        return true
    end,
    
    -- Sync all active stations to a player
    SyncToPlayer = function(self, ply)
        if not IsValid(ply) then return end
        
        print(string.format("[rRadio] Syncing %d stations to %s", table.Count(self.Stations), ply:Nick()))
        
        for entIndex, stationData in pairs(self.Stations) do
            local ent = stationData.entity
            if IsValid(ent) then
                net.Start("rRadio_StreamUpdate")
                    net.WriteEntity(ent)
                    net.WriteBool(false)
                    net.WriteString(stationData.name)
                    net.WriteString(stationData.url)
                    net.WriteFloat(stationData.volume)
                net.Send(ply)
            else
                -- Cleanup invalid entities
                self.Stations[entIndex] = nil
            end
        end
    end,
    
    -- Get station data for an entity
    GetStationData = function(self, ent)
        if not IsValid(ent) then return nil end
        return self.Stations[ent:EntIndex()]
    end,
    
    -- Periodic cleanup of invalid stations
    CleanupInvalid = function(self)
        for entIndex, stationData in pairs(self.Stations) do
            if not IsValid(stationData.entity) then
                self.Stations[entIndex] = nil
                print(string.format("[rRadio] Cleaned up invalid station %d", entIndex))
            end
        end
    end
}

-- Initialize the station manager
hook.Add("Initialize", "rRadio_StationManager", function()
    rRadio.ActiveStations:Initialize()
    
    -- Set up periodic cleanup
    timer.Create("rRadio_StationCleanup", 60, 0, function()
        rRadio.ActiveStations:CleanupInvalid()
    end)
end)

-- Handle station selection
net.Receive("rRadio_SelectStation", function(len, ply)
    local ent = net.ReadEntity()
    local name = net.ReadString()
    local url = net.ReadString()
    
    print(string.format("[rRadio] Received station selection from %s - Entity: %s, Name: %s, URL: %s",
        ply:Nick(), tostring(ent), name, url))
    
    if not IsValid(ent) then 
        print("[rRadio] Station selection failed - Invalid entity")
        return 
    end
    if not (ent:GetClass() == "rradio_boombox" or ent:IsVehicle()) then 
        print("[rRadio] Station selection failed - Invalid entity type:", ent:GetClass())
        return 
    end
    
    -- Check if stopping
    if name == "" and url == "" then
        print("[rRadio] Stopping station for entity", tostring(ent))
        rRadio.ActiveStations:RemoveStation(ent)
        return
    end
    
    -- Set the station
    local success = rRadio.ActiveStations:SetStation(ent, {
        name = name,
        url = url,
        volume = ent.GetVolume and ent:GetVolume() or 100,
        type = ent:IsVehicle() and "vehicle" or "entity"
    })
    
    print(string.format("[rRadio] Station selection %s for entity %s", 
        success and "succeeded" or "failed", tostring(ent)))
end) 