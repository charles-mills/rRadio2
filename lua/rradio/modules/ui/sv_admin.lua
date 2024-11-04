util.AddNetworkString("rRadio_AdminCleanup")
util.AddNetworkString("rRadio_AdminCleanupResponse")

net.Receive("rRadio_AdminCleanup", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local count = 0
    for _, ent in ipairs(ents.FindByClass("rradio_boombox")) do
        if IsValid(ent) then
            ent:Remove()
            count = count + 1
        end
    end

    net.Start("rRadio_AdminCleanupResponse")
        net.WriteUInt(count, 8)
    net.Send(ply)
end) 