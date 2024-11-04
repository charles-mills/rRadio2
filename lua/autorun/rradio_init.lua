rRadio = rRadio or {}

-- Load order management
local function LoadFile(path, realm)
    if realm == "sv" and SERVER then
        include(path)
    elseif realm == "cl" and CLIENT then
        include(path)
    elseif realm == "sh" then
        if SERVER then
            AddCSLuaFile(path)
        end
        include(path)
    end
end

-- Core files
LoadFile("rradio/core/sh_config.lua", "sh")
LoadFile("rradio/core/sh_utils.lua", "sh")
LoadFile("rradio/core/sh_language.lua", "sh")

-- Network strings (shared)
if SERVER then
    util.AddNetworkString("rRadio_OpenInterface")
    util.AddNetworkString("rRadio_SelectStation")
    util.AddNetworkString("rRadio_StreamUpdate")
    util.AddNetworkString("rRadio_RemoveEntity")
    util.AddNetworkString("rRadio_VehicleStation")
end

-- Base UI system must be loaded before any UI components
if SERVER then
    AddCSLuaFile("rradio/modules/ui/cl_base.lua")
else
    include("rradio/modules/ui/cl_base.lua")
end

-- Modules
LoadFile("rradio/modules/sh_manager.lua", "sh")
LoadFile("rradio/modules/vehicles/sh_radio.lua", "sh")

if SERVER then
    LoadFile("rradio/modules/stations/sv_manager.lua", "sv")
    LoadFile("rradio/modules/ui/sv_admin.lua", "sv")
    
    -- Add client files to download
    local files = {
        "rradio/modules/ui/cl_theme.lua",
        "rradio/modules/streams/cl_manager.lua",
        "rradio/modules/favorites/cl_favorites.lua",
        "rradio/modules/ui/panels/cl_menu.lua",
        "rradio/modules/ui/panels/cl_radiolist.lua"
    }
    
    for _, file in ipairs(files) do
        AddCSLuaFile(file)
    end
else
    -- Load client modules in correct order
    LoadFile("rradio/modules/ui/cl_base.lua", "cl")
    LoadFile("rradio/modules/ui/cl_theme.lua", "cl")
    LoadFile("rradio/modules/streams/cl_manager.lua", "cl")
    LoadFile("rradio/modules/favorites/cl_favorites.lua", "cl")
    
    -- Then load UI panels
    LoadFile("rradio/modules/ui/panels/cl_menu.lua", "cl")
    LoadFile("rradio/modules/ui/panels/cl_radiolist.lua", "cl")
end 