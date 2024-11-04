rRadio.VehicleRadio = {
    -- Valid vehicle base classes and specific vehicles
    ValidVehicles = {
        -- Base classes
        ["prop_vehicle_jeep"] = true,
        ["prop_vehicle_airboat"] = true,
        ["gmod_sent_vehicle_fphysics_base"] = true,

        -- Vehicle seats/pods
        ["prop_vehicle_prisoner_pod"] = true,
        ["Seat_Airboat"] = true,
        ["Seat_Jeep"] = true,
    },

    -- Vehicle mod compatibility
    VehicleMods = {
        simfphys = true,  -- SimfPhys
        LFS = true,       -- LFS (Let's Fly Stuff)
        WAC = true        -- WAC Aircraft
    },

    IsValidVehicle = function(self, ent)
        if not IsValid(ent) then return false end
        
        -- Check base vehicle class
        if self.ValidVehicles[ent:GetClass()] then return true end
        
        -- Check parent entity (for seats/pods)
        local parent = ent:GetParent()
        if IsValid(parent) and self.ValidVehicles[parent:GetClass()] then
            return true
        end

        -- Check vehicle mod compatibility
        if ent.LFS or (ent.isWacAircraft and self.VehicleMods.WAC) then
            return true
        end
        
        -- SimfPhys compatibility
        if self.VehicleMods.simfphys and ent.GetVehicleType and type(ent.GetVehicleType) == "function" then
            return true
        end

        return false
    end,

    GetDriver = function(self, ent)
        if not IsValid(ent) then return end

        -- WAC Aircraft compatibility
        if ent.isWacAircraft and ent.seats and IsValid(ent.seats[1]) then
            return ent.seats[1]:GetDriver()
        end

        -- Standard vehicles
        if ent.GetDriver then
            return ent:GetDriver()
        end

        -- Vehicle seats/pods
        if ent:IsVehicle() then
            return ent:GetDriver()
        end

        return nil
    end,

    GetRange = function(self)
        return GetConVar("rradio_range_vehicle"):GetInt()
    end
}

if SERVER then
    util.AddNetworkString("rRadio_VehicleStation")
    
    net.Receive("rRadio_VehicleStation", function(len, ply)
        local vehicle = net.ReadEntity()
        local name = net.ReadString()
        local url = net.ReadString()
        
        -- Validate vehicle and player
        if not IsValid(vehicle) or not IsValid(ply) or 
           not rRadio.VehicleRadio:IsValidVehicle(vehicle) or
           rRadio.VehicleRadio:GetDriver(vehicle) != ply then
            return
        end
        
        -- Validate URL
        if not rRadio.StationManager:ValidateStation(url) then return end
        
        vehicle.RadioStation = {name = name, url = url}
        vehicle.RadioPlaying = true
        
        -- Notify nearby players
        net.Start("rRadio_VehicleStation")
            net.WriteEntity(vehicle)
            net.WriteString(name)
            net.WriteString(url)
        net.Broadcast()
    end)
end

if CLIENT then
    -- Remove old stream management code
    local activeVehicle = nil
    
    hook.Add("PlayerEnteredVehicle", "rRadio_VehicleRadio", function(ply, vehicle)
        if ply == LocalPlayer() and rRadio.VehicleRadio:IsValidVehicle(vehicle) then
            activeVehicle = vehicle
            
            if vehicle.RadioPlaying and vehicle.RadioStation then
                rRadio.StreamManager:CreateStream({
                    entity = vehicle,
                    url = vehicle.RadioStation.url,
                    name = vehicle.RadioStation.name,
                    volume = 1,
                    range = rRadio.VehicleRadio:GetRange(),
                    type = "vehicle",
                    falloff = GetConVar("rradio_falloff_vehicle"):GetFloat()
                })
            end
        end
    end)
    
    hook.Add("PlayerLeaveVehicle", "rRadio_VehicleRadio", function(ply, vehicle)
        if ply == LocalPlayer() and vehicle == activeVehicle then
            rRadio.StreamManager:CleanupStream(vehicle:EntIndex())
            activeVehicle = nil
        end
    end)
    
    net.Receive("rRadio_VehicleStation", function()
        local vehicle = net.ReadEntity()
        local name = net.ReadString()
        local url = net.ReadString()
        
        if IsValid(vehicle) and rRadio.VehicleRadio:IsValidVehicle(vehicle) then
            vehicle.RadioStation = {name = name, url = url}
            vehicle.RadioPlaying = true
            
            if vehicle == activeVehicle then
                rRadio.StreamManager:CleanupStream(vehicle:EntIndex())
                rRadio.StreamManager:CreateStream({
                    entity = vehicle,
                    url = url,
                    name = name,
                    volume = 1,
                    range = rRadio.VehicleRadio:GetRange(),
                    type = "vehicle",
                    falloff = GetConVar("rradio_falloff_vehicle"):GetFloat()
                })
            end
        end
    end)
end 