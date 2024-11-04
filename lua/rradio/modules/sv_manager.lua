util.AddNetworkString("rRadio_SelectStation")

net.Receive("rRadio_SelectStation", function(len, ply)
    local ent = net.ReadEntity()
    local name = net.ReadString()
    local url = net.ReadString()
    
    if IsValid(ent) and ent:GetClass() == "rradio_boombox" then
        ent:SetStation(name, url, ply)
    end
end) 