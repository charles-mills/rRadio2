rRadio.ActiveStations = {
    -- Store active stations by entity
    Stations = {},

    -- Add or update a station
    SetStation = function(self, ent, data)
        if not IsValid(ent) then return end
        
        self.Stations[ent:EntIndex()] = {
            name = data.name,
            url = data.url,
            volume = data.volume or 100,
            timestamp = CurTime()
        }
        
        -- Notify nearby players
        net.Start("rRadio_StreamUpdate")
            net.WriteEntity(ent)
            net.WriteString(data.name)
            net.WriteString(data.url)
            net.WriteFloat(data.volume or 100)
        net.SendPVS(ent:GetPos())
    end,

    -- Remove a station
    RemoveStation = function(self, ent)
        if not IsValid(ent) then return end
        self.Stations[ent:EntIndex()] = nil
        
        -- Notify nearby players
        net.Start("rRadio_StreamUpdate")
            net.WriteEntity(ent)
            net.WriteBool(true) -- Stop flag
        net.SendPVS(ent:GetPos())
    end,

    -- Send active stations to a player
    SyncToPlayer = function(self, ply)
        for entIdx, stationData in pairs(self.Stations) do
            local ent = Entity(entIdx)
            if IsValid(ent) then
                net.Start("rRadio_StreamUpdate")
                    net.WriteEntity(ent)
                    net.WriteString(stationData.name)
                    net.WriteString(stationData.url)
                    net.WriteFloat(stationData.volume)
                net.Send(ply)
            end
        end
    end
}

-- Network handlers
util.AddNetworkString("rRadio_SelectStation")
util.AddNetworkString("rRadio_StreamUpdate")

net.Receive("rRadio_SelectStation", function(len, ply)
    local ent = net.ReadEntity()
    local name = net.ReadString()
    local url = net.ReadString()
    
    if IsValid(ent) and ent:GetClass() == "rradio_boombox" then
        rRadio.ActiveStations:SetStation(ent, {
            name = name,
            url = url,
            volume = ent:GetVolume()
        })
    end
end)

-- Sync active stations to players when they spawn
hook.Add("PlayerInitialSpawn", "rRadio_SyncStations", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            rRadio.ActiveStations:SyncToPlayer(ply)
        end
    end)
end) 