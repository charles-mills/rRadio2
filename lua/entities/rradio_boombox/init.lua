AddCSLuaFile("cl_init.lua")
include("shared.lua")

-- Network strings
util.AddNetworkString("rRadio_OpenInterface")
util.AddNetworkString("rRadio_RemoveEntity")
util.AddNetworkString("rRadio_StreamUpdate")

function ENT:Initialize()
    -- Try to use configured model, fall back if not found
    local modelPath = self:GetGolden() and rRadio.Config.Entities.Models.golden or rRadio.Config.Entities.Models.default
    
    if not util.IsValidModel(modelPath) then
        modelPath = rRadio.Config.Entities.Models.fallback
    end
    
    self:SetModel(modelPath)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    -- Default properties
    self:SetVolume(50)
    self:SetPlaying(false)
    self:SetGolden(false)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    -- Call hook for additional initialization
    rRadio.CallHook("BoomboxInitialized", self)
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not self:CanUse(activator) then return end
    
    -- Open radio interface
    net.Start("rRadio_OpenInterface")
        net.WriteEntity(self)
    net.Send(activator)
end

function ENT:SetStation(name, url, ply)
    if not rRadio.Utils.ValidateURL(url) then return false end
    if not self:CanUse(ply) then return false end
    
    -- Check if player has permission
    if IsValid(ply) and not rRadio.CallHook("CanChangeStation", ply, self)[1] then
        return false
    end
    
    self:SetStationName(name)
    self:SetStationURL(url)
    self:SetPlaying(true)
    
    -- Notify nearby players
    net.Start("rRadio_StreamUpdate")
        net.WriteEntity(self)
        net.WriteString(name)
        net.WriteString(url)
        net.WriteFloat(self:GetVolume())
    net.SendPVS(self:GetPos())
    
    return true
end

function ENT:StopPlaying()
    self:SetPlaying(false)
    self:SetStationName("")
    self:SetStationURL("")
    
    -- Notify nearby players
    net.Start("rRadio_StreamUpdate")
        net.WriteEntity(self)
        net.WriteBool(false)
    net.SendPVS(self:GetPos())
end

function ENT:SetVolume(vol, ply)
    if IsValid(ply) and not self:CanUse(ply) then return false end
    
    vol = math.Clamp(vol, 0, 100)
    self:SetNWFloat("Volume", vol)
    
    -- Notify nearby players if playing
    if self:GetPlaying() then
        net.Start("rRadio_StreamUpdate")
            net.WriteEntity(self)
            net.WriteFloat(vol)
        net.SendPVS(self:GetPos())
    end
    
    return true
end

function ENT:OnRemove()
    -- Stop audio for all players
    net.Start("rRadio_RemoveEntity")
        net.WriteEntity(self)
    net.SendPVS(self:GetPos())
    
    rRadio.CallHook("BoomboxRemoved", self)
end

-- Prevent damage if configured
function ENT:OnTakeDamage(dmg)
    if not rRadio.Config.Entities.AllowDamage then
        return 0
    end
    return dmg:GetDamage()
end

-- Prevent use while being held
function ENT:CanUse(ply)
    if not IsValid(ply) then return false end
    
    -- Check if being held by physgun
    local holder = self:GetPhysicsAttacker()
    if IsValid(holder) and holder != ply then
        return false
    end
    
    return true
end
