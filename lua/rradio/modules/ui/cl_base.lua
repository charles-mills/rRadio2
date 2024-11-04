rRadio.UI = rRadio.UI or {}
rRadio.UI.Panels = rRadio.UI.Panels or {}

-- Base Panel class
local BASE = {}

function BASE:Init()
    self.animations = {}
    self.nextUpdate = 0
end

function BASE:ScaleToScreen()
    local w, h = self:GetSize()
    self:SetSize(rRadio.UI.ScaleW(w), rRadio.UI.ScaleH(h))
end

function BASE:CreateScaledFont(name, size, weight)
    return rRadio.UI.ScaleFont(name, size, weight)
end

function BASE:GetThemeColor(key, alpha)
    return rRadio.Theme:GetColor(key, alpha)
end

vgui.Register("rRadio_BasePanel", BASE, "DPanel")

-- Theme Panel class
local THEME = table.Copy(BASE)

function THEME:Init()
    BASE.Init(self)
    self.themeColors = {}
    self:InitializeTheme()
end

function THEME:InitializeTheme()
    self.themeColors = {
        background = self:GetThemeColor("background"),
        text = self:GetThemeColor("text")
    }
end

vgui.Register("rRadio_ThemePanel", THEME, "rRadio_BasePanel")

-- Theme Frame class
local FRAME = {}

function FRAME:Init()
    self.animations = {}
    self.nextUpdate = 0
    self.themeColors = {}
    self:InitializeTheme()
end

function FRAME:ScaleToScreen()
    local w, h = self:GetSize()
    self:SetSize(rRadio.UI.ScaleW(w), rRadio.UI.ScaleH(h))
end

function FRAME:CreateScaledFont(name, size, weight)
    return rRadio.UI.ScaleFont(name, size, weight)
end

function FRAME:GetThemeColor(key, alpha)
    return rRadio.Theme:GetColor(key, alpha)
end

function FRAME:InitializeTheme()
    self.themeColors = {
        background = self:GetThemeColor("background"),
        text = self:GetThemeColor("text")
    }
end

vgui.Register("rRadio_Frame", FRAME, "DFrame")

-- UI Factory
rRadio.UI.Create = function(panelType, parent)
    if not rRadio.UI.Panels[panelType] then
        error("Attempted to create unknown panel type: " .. panelType)
        return nil
    end
    
    local panel = vgui.Create(rRadio.UI.Panels[panelType].base, parent)
    return panel
end

-- Panel Registration
rRadio.UI.RegisterPanel = function(name, methods, baseClass)
    local PANEL = table.Copy(methods)
    local base = baseClass or "rRadio_ThemePanel"
    
    -- Set up inheritance
    PANEL.Base = base
    PANEL.BaseClass = _G[base]
    
    -- Register the panel
    rRadio.UI.Panels[name] = {
        base = "rRadio_" .. name
    }
    
    vgui.Register("rRadio_" .. name, PANEL, base)
end