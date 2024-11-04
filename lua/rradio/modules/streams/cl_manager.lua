rRadio.StreamManager = {
    -- Active streams storage
    Streams = {},
    
    -- Stream status enum
    Status = {
        LOADING = 0,
        PLAYING = 1,
        STOPPED = 2,
        ERROR = 3
    },
    
    -- Initialize the stream manager
    Initialize = function(self)
        -- Clean up any existing streams on initialization
        self:CleanupAllStreams()
        
        -- Register network handlers
        self:RegisterNetworking()
        
        -- Register hooks
        self:RegisterHooks()
    end,
    
    -- Create a new stream
    CreateStream = function(self, data)
        if not data.url or not data.entity then return false end
        
        -- Generate unique stream ID
        local streamID = data.entity:EntIndex()
        
        -- Clean up existing stream if present
        self:CleanupStream(streamID)
        
        -- Create new stream entry
        self.Streams[streamID] = {
            entity = data.entity,
            url = data.url,
            name = data.name or "Unknown",
            volume = data.volume or 1,
            status = self.Status.LOADING,
            position = data.entity:GetPos(),
            range = data.range or rRadio.Utils.GetRange(data.entity),
            falloff = data.falloff or GetConVar("rradio_falloff_default"):GetFloat(),
            lastUpdate = CurTime(),
            channel = nil,
            type = data.type or "entity", -- entity/vehicle
            metadata = data.metadata or {}
        }
        
        -- Start playback
        self:StartStream(streamID)
        
        return streamID
    end,
    
    -- Start stream playback
    StartStream = function(self, streamID)
        local stream = self.Streams[streamID]
        if not stream then return false end
        
        sound.PlayURL(stream.url, "3d noblock", function(channel, errorID, errorName)
            if not IsValid(stream.entity) then 
                self:CleanupStream(streamID)
                return
            end
            
            if channel then
                stream.channel = channel
                stream.status = self.Status.PLAYING
                
                -- Configure channel
                channel:SetPos(stream.position)
                channel:Set3DFadeDistance(stream.range * 0.25, stream.range)
                channel:SetVolume(stream.volume)
                channel:EnableLooping(true)
                
                -- Call hook for successful stream start
                hook.Run("rRadio_StreamStarted", stream.entity, stream)
            else
                stream.status = self.Status.ERROR
                stream.error = {id = errorID, name = errorName}
                
                -- Call hook for stream error
                hook.Run("rRadio_StreamError", stream.entity, errorID, errorName)
            end
        end)
    end,
    
    -- Update stream properties
    UpdateStream = function(self, streamID, data)
        local stream = self.Streams[streamID]
        if not stream then return false end
        
        -- Update basic properties
        if data.volume then stream.volume = data.volume end
        if data.range then stream.range = data.range end
        if data.position then stream.position = data.position end
        
        -- Update channel if active
        if IsValid(stream.channel) then
            if data.volume then stream.channel:SetVolume(data.volume) end
            if data.position then stream.channel:SetPos(data.position) end
            if data.range then 
                stream.channel:Set3DFadeDistance(data.range * 0.25, data.range)
            end
        end
        
        stream.lastUpdate = CurTime()
        return true
    end,
    
    -- Stop and cleanup a stream
    CleanupStream = function(self, streamID)
        local stream = self.Streams[streamID]
        if not stream then return false end
        
        if IsValid(stream.channel) then
            stream.channel:Stop()
            stream.channel = nil
        end
        
        self.Streams[streamID] = nil
        hook.Run("rRadio_StreamStopped", stream.entity)
        return true
    end,
    
    -- Clean up all streams
    CleanupAllStreams = function(self)
        for streamID, _ in pairs(self.Streams) do
            self:CleanupStream(streamID)
        end
    end,
    
    -- Network handlers
    RegisterNetworking = function(self)
        net.Receive("rRadio_StreamUpdate", function()
            local ent = net.ReadEntity()
            local data = net.ReadTable()
            
            if IsValid(ent) then
                local streamID = ent:EntIndex()
                
                if data.stop then
                    self:CleanupStream(streamID)
                else
                    if self.Streams[streamID] then
                        self:UpdateStream(streamID, data)
                    else
                        self:CreateStream({
                            entity = ent,
                            url = data.url,
                            name = data.name,
                            volume = data.volume,
                            range = data.range,
                            type = data.type
                        })
                    end
                end
            end
        end)
    end,
    
    -- Hook handlers
    RegisterHooks = function(self)
        -- Clean up streams when entities are removed
        hook.Add("EntityRemoved", "rRadio_StreamCleanup", function(ent)
            local streamID = ent:EntIndex()
            if self.Streams[streamID] then
                self:CleanupStream(streamID)
            end
        end)
        
        -- Update stream positions
        hook.Add("Think", "rRadio_StreamPositions", function()
            for streamID, stream in pairs(self.Streams) do
                if IsValid(stream.entity) then
                    local newPos = stream.entity:GetPos()
                    if newPos != stream.position then
                        self:UpdateStream(streamID, {position = newPos})
                    end
                else
                    self:CleanupStream(streamID)
                end
            end
        end)
    end,
    
    -- Utility functions
    GetStreamByEntity = function(self, entity)
        return self.Streams[entity:EntIndex()]
    end,
    
    GetActiveStreams = function(self)
        return self.Streams
    end,
    
    IsPlaying = function(self, entity)
        local stream = self:GetStreamByEntity(entity)
        return stream and stream.status == self.Status.PLAYING
    end
}

-- Initialize when the file is loaded
rRadio.StreamManager:Initialize() 