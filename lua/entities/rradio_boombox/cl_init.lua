include("shared.lua")

function ENT:Initialize()
    -- No need to store streams locally anymore
    -- StreamManager will handle everything
end

function ENT:OnRemove()
    -- StreamManager will handle cleanup
end

function ENT:Think()
    if not self:GetPlaying() then return end
    
    -- StreamManager handles all position updates and range checks
    local stream = rRadio.StreamManager:GetStreamByEntity(self)
    if not stream and self:GetPlaying() then
        -- Create new stream if none exists
        rRadio.StreamManager:CreateStream({
            entity = self,
            url = self:GetStationURL(),
            name = self:GetStationName(),
            volume = self:GetVolume() / 100,
            range = self:GetRange(),
            type = "entity"
        })
    end
end

-- Network handlers
net.Receive("rRadio_StreamUpdate", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    
    local data = {
        stop = net.ReadBool()
    }
    
    if not data.stop then
        data.name = net.ReadString()
        data.url = net.ReadString()
        data.volume = net.ReadFloat() / 100
    end
    
    if data.stop then
        rRadio.StreamManager:CleanupStream(ent:EntIndex())
    else
        local stream = rRadio.StreamManager:GetStreamByEntity(ent)
        if stream then
            rRadio.StreamManager:UpdateStream(ent:EntIndex(), data)
        else
            rRadio.StreamManager:CreateStream({
                entity = ent,
                url = data.url,
                name = data.name,
                volume = data.volume,
                range = ent:GetRange(),
                type = "entity"
            })
        end
    end
end)

net.Receive("rRadio_RemoveEntity", function()
    local ent = net.ReadEntity()
    if IsValid(ent) then
        rRadio.StreamManager:CleanupStream(ent:EntIndex())
    end
end)

function ENT:Draw()
    self:DrawModel()
    
    if not self:GetPlaying() then return end
    
    -- Draw status indicator
    local pos = self:GetPos() + self:GetUp() * 15
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Up(), -90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    
    cam.Start3D2D(pos, ang, 0.25)
        -- Background
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(-100, -15, 200, 30)
        
        -- Station name
        draw.SimpleText(self:GetStationName(), "DermaLarge", 0, 0, 
            self:GetGolden() and Color(255, 215, 0) or color_white, 
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end 