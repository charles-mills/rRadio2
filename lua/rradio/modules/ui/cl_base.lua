rRadio.UI = rRadio.UI or {}
rRadio.UI.Panels = rRadio.UI.Panels or {}

-- Base Panel class
local PANEL = {}

function PANEL:SetupAnimations()
    -- Base animation setup
    self.animations = {}
    self.nextUpdate = 0
end

function PANEL:Init()
    self:SetupAnimations()
end

function PANEL:ScaleToScreen()
    local w, h = self:GetSize()
    self:SetSize(rRadio.UI.ScaleW(w), rRadio.UI.ScaleH(h))
end

function PANEL:CreateScaledFont(name, size, weight)
    return rRadio.UI.ScaleFont(name, size, weight)
end

function PANEL:GetThemeColor(key, alpha)
    return rRadio.Theme:GetColor(key, alpha)
end

function PANEL:UpdateAnimations()
    -- Override in child panels
end

function PANEL:Think()
    if CurTime() < self.nextUpdate then return end
    self.nextUpdate = CurTime() + rRadio.Config.UI.UpdateRate
    
    self:UpdateAnimations()
end

vgui.Register("rRadio_BasePanel", PANEL, "DPanel")

-- Theme Panel class
local THEME_PANEL = {}
setmetatable(THEME_PANEL, {__index = PANEL})

function THEME_PANEL:Init()
    PANEL.Init(self)
    self.themeColors = {}
    self:InitializeTheme()
end

function THEME_PANEL:InitializeTheme()
    self.themeColors = {
        background = self:GetThemeColor("background"),
        text = self:GetThemeColor("text")
    }
end

vgui.Register("rRadio_ThemePanel", THEME_PANEL, "rRadio_BasePanel")

-- Theme Frame class
local THEME_FRAME = table.Copy(THEME_PANEL)

function THEME_FRAME:Init()
    THEME_PANEL.Init(self)
end

vgui.Register("rRadio_ThemeFrame", THEME_FRAME, "DFrame")

-- UI Factory
rRadio.UI.Create = function(panelType, parent)
    if not rRadio.UI.Panels[panelType] then
        error("Attempted to create unknown panel type: " .. panelType)
        return nil
    end
    
    local panel = vgui.Create(rRadio.UI.Panels[panelType].base, parent)
    if panel then
        panel:SetupFromConfig(rRadio.UI.Panels[panelType].config)
    end
    return panel
end

-- Panel Registration
rRadio.UI.RegisterThemePanel = function(name, methods, config)
    local PANEL = table.Copy(methods)
    local baseClass = methods.baseClass or "rRadio_ThemePanel"
    
    -- Ensure proper inheritance
    if not PANEL.BaseClass then
        PANEL.BaseClass = _G[baseClass]
    end
    
    rRadio.UI.Panels[name] = {
        base = "rRadio_" .. name,
        config = config or {}
    }
    
    vgui.Register("rRadio_" .. name, PANEL, baseClass)
end