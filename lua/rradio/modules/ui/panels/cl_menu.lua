-- Single menu instance tracking
local activeMenu = nil

-- Network handler for opening the menu
net.Receive("rRadio_OpenInterface", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    
    -- Remove existing menu if it exists
    if IsValid(activeMenu) then
        activeMenu:Remove()
        activeMenu = nil
    end
    
    -- Create new menu
    activeMenu = rRadio.UI.Create("Menu")
    activeMenu.Entity = ent
end)

local MENU = {
    baseClass = "rRadio_ThemeFrame"
}

function MENU:Init()
    self.BaseClass.Init(self)
    
    -- Set up window properties
    self:SetSize(400, 600)
    self:ScaleToScreen()
    self:Center()
    self:ShowCloseButton(false)
    self:SetTitle("")
    self:MakePopup()
    
    -- Track active components
    self.components = {}
    
    -- Create components
    self:CreateTitleBar()
    self:CreateSearchBar()
    self:CreateList()
    self:CreateControls()
end

function MENU:InitializeTheme()
    self.themeColors = {
        background = self:GetThemeColor("background"),
        foreground = self:GetThemeColor("foreground"),
        text = self:GetThemeColor("text")
    }
end

function MENU:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, self.themeColors.background)
end

function MENU:CreateHeader()
    local header = vgui.Create("DPanel", self)
    header:Dock(TOP)
    header:SetTall(40)
    header:DockMargin(10, 10, 10, 5)
    header.Paint = function() end

    -- Radio icon
    local icon = vgui.Create("DImage", header)
    icon:SetSize(24, 24)
    icon:Dock(LEFT)
    icon:DockMargin(5, 8, 5, 8)
    icon:SetImage(rRadio.Config.UI.Icons.radio)

    -- Title
    local title = vgui.Create("DLabel", header)
    title:Dock(LEFT)
    title:SetText("Select a Country")
    title:SetFont(self:CreateScaledFont("Title", 20))
    title:SetTextColor(self.themeColors.text)
    title:SizeToContents()

    -- Settings button (admin only)
    if LocalPlayer():IsAdmin() then
        local settings = vgui.Create("DImageButton", header)
        settings:SetSize(16, 16)
        settings:Dock(RIGHT)
        settings:DockMargin(5, 12, 5, 12)
        settings:SetImage(rRadio.Config.UI.Icons.settings)
        self:AddComponent("settings", settings)
    end

    -- Close button
    local close = vgui.Create("DImageButton", header)
    close:SetSize(16, 16)
    close:Dock(RIGHT)
    close:DockMargin(5, 12, 5, 12)
    close:SetImage(rRadio.Config.UI.Icons.close)
    close.DoClick = function() self:Remove() end
    
    self:AddComponent("header", header)
end

function MENU:CreateSearch()
    local search = vgui.Create("DTextEntry", self)
    search:Dock(TOP)
    search:DockMargin(10, 5, 10, 5)
    search:SetTall(30)
    search:SetFont(self:CreateScaledFont("Search", 16))
    search:SetPlaceholderText("Search...")
    search.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, self.themeColors.foreground)
        s:DrawTextEntryText(
            self.themeColors.text,
            self:GetThemeColor("accent"),
            self.themeColors.text
        )
    end
    
    self:AddComponent("search", search)
end

function MENU:CreateList()
    self.radioList = rRadio.UI.Create("RadioList", self)
    self.radioList:Dock(FILL)
    self.radioList:DockMargin(10, 5, 10, 5)
    self.radioList:LoadCountries() -- Start with country list
    
    self:AddComponent("radioList", self.radioList)
end

function MENU:OnCountrySelected(country)
    -- Update title
    if self.components.titleBar then
        self.components.titleBar:SetTitle(country)
    end
    
    -- Load stations for country
    self.radioList:LoadStations(country)
end

function MENU:CreateControls()
    local controls = vgui.Create("DPanel", self)
    controls:Dock(BOTTOM)
    controls:SetTall(50)
    controls:DockMargin(10, 5, 10, 10)
    controls.Paint = function() end

    -- Stop button
    local stop = vgui.Create("DButton", controls)
    stop:Dock(LEFT)
    stop:SetWide(80)
    stop:SetText("STOP")
    stop:SetFont(self:CreateScaledFont("Button", 16))
    stop.Paint = function(s, w, h)
        local color = s:IsHovered() and self:GetThemeColor("error") or self:GetThemeColor("item")
        draw.RoundedBox(6, 0, 0, w, h, color)
    end

    -- Volume icon
    local volIcon = vgui.Create("DImage", controls)
    volIcon:SetSize(24, 24)
    volIcon:Dock(LEFT)
    volIcon:DockMargin(10, 13, 5, 13)
    volIcon:SetImage(rRadio.Config.UI.Icons.volume)

    -- Volume slider
    local volume = vgui.Create("DSlider", controls)
    volume:Dock(FILL)
    volume:DockMargin(5, 15, 0, 15)
    volume:SetSlideX(0.75)
    volume.Paint = function(s, w, h)
        draw.RoundedBox(2, 0, h/2-1, w, 2, self:GetThemeColor("item"))
        draw.RoundedBox(2, 0, h/2-1, w * s:GetSlideX(), 2, self:GetThemeColor("accent"))
    end
    
    self:AddComponent("controls", controls)
end

rRadio.UI.RegisterThemePanel("Menu", MENU, {
    setup = function(panel)
        panel:SetDraggable(true)
        panel:SetSizable(true)
        panel:SetMinWidth(rRadio.Config.UI.MinWidth)
        panel:SetMinHeight(rRadio.Config.UI.MinHeight)
        panel.hookID = "rRadio_Menu_" .. tostring(panel)
    end
}) 