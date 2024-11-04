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
        
        -- Create position update timer
        timer.Create("rRadio_StreamPositions", 0.1, 0, function()
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

        -- Create periodic cleanup timer
        timer.Create("rRadio_StreamCleanup", 5, 0, function()
            self:PerformCleanup()
        end)
    end,

    PerformCleanup = function(self)
        for streamID, stream in pairs(self.Streams) do
            -- Check for invalid entities
            if not IsValid(stream.entity) then
                self:CleanupStream(streamID)
                continue
            end

            -- Check for out-of-range streams
            local dist = LocalPlayer():GetPos():DistToSqr(stream.position)
            if dist > (stream.range * stream.range * 1.5) then -- 1.5x buffer
                self:CleanupStream(streamID)
            end
        end
    end,

    -- Create a new stream
    CreateStream = function(self, data)
        if not data.url or not data.entity then return false end
        
        -- Check if stream can start
        if rRadio.Hooks.PreStreamStart(data.entity, data) == false then
            return false
        end
        
        print("[rRadio] Creating stream for", data.name)
        
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
            type = data.type or "entity",
            metadata = data.metadata or {}
        }
        
        -- Start playback
        self:StartStream(streamID)
        
        -- Call post-start hook
        rRadio.Hooks.PostStreamStart(data.entity, data)
        
        return streamID
    end,
    
    -- Start stream playback
    StartStream = function(self, streamID)
        local stream = self.Streams[streamID]
        if not stream then return false end
        
        print("[rRadio] Starting stream", stream.name)

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
                
                print("[rRadio] Stream started successfully")
                hook.Run("rRadio_StreamStarted", stream.entity, stream)
            else
                stream.status = self.Status.ERROR
                stream.error = {id = errorID, name = errorName}
                
                print("[rRadio] Stream error:", errorName)
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
        
        -- Check if stream can stop
        if rRadio.Hooks.PreStreamStop(stream.entity) == false then
            return false
        end
        
        if IsValid(stream.channel) then
            stream.channel:Stop()
            stream.channel = nil
        end
        
        self.Streams[streamID] = nil
        hook.Run("rRadio_StreamStopped", stream.entity)
        
        -- Call post-stop hook
        rRadio.Hooks.PostStreamStop(stream.entity)
        
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
            print("[rRadio] Received stream update for entity:", tostring(ent))
            
            if not IsValid(ent) then 
                print("[rRadio] Stream update failed - Invalid entity")
                return 
            end
            
            local stop = net.ReadBool()
            if stop then
                print("[rRadio] Stopping stream for entity:", tostring(ent))
                self:CleanupStream(ent:EntIndex())
                return
            end
            
            local data = {
                name = net.ReadString(),
                url = net.ReadString(),
                volume = net.ReadFloat()
            }
            
            print(string.format("[rRadio] Stream data - Name: %s, URL: %s, Volume: %d",
                data.name, data.url, data.volume))
            
            -- Update existing stream or create new one
            local streamID = ent:EntIndex()
            if self.Streams[streamID] then
                print("[rRadio] Updating existing stream:", streamID)
                self:UpdateStream(streamID, data)
            else
                print("[rRadio] Creating new stream:", streamID)
                self:CreateStream({
                    entity = ent,
                    url = data.url,
                    name = data.name,
                    volume = data.volume,
                    position = ent:GetPos(),
                    range = ent:GetRange(),
                    type = "entity"
                })
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
    end,

    OnRemove = function(self)
        timer.Remove("rRadio_StreamPositions")
        timer.Remove("rRadio_StreamCleanup")
        self:CleanupAllStreams()
    end
}

-- Initialize when the file is loaded
rRadio.StreamManager:Initialize() 