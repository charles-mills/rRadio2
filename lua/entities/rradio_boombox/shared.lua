ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Radio Boombox"
ENT.Author = "rRadio"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category = "rRadio"

-- Network variables
function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Golden")
    self:NetworkVar("Bool", 1, "Playing")
    self:NetworkVar("Float", 0, "Volume")
    self:NetworkVar("String", 0, "StationName")
    self:NetworkVar("String", 1, "StationURL")
    self:NetworkVar("Entity", 0, "Owner")
end

-- Shared functions
function ENT:GetRange()
    return self:GetGolden() and GetConVar("rradio_range_golden"):GetInt() 
                             or GetConVar("rradio_range_default"):GetInt()
end

function ENT:CanUse(ply)
    if not IsValid(ply) then return false end
    
    -- Owner check
    if IsValid(self:GetOwner()) and self:GetOwner() != ply then
        return false
    end
    
    -- Golden boombox restriction
    if self:GetGolden() and rRadio.Config.Permissions.RestrictGoldenBoombox then
        return ply:IsAdmin()
    end
    
    return true
end 