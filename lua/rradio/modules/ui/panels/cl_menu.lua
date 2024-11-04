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

local MENU = {}

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

function MENU:CreateTitleBar()
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
    
    header.SetTitle = function(_, text)
        title:SetText(rRadio.Utils.FormatName(text))
        title:SizeToContents()
    end

    local settings = vgui.Create("DImageButton", header)
    settings:SetSize(16, 16)
    settings:Dock(RIGHT)
    settings:DockMargin(5, 12, 5, 12)
    settings:SetImage(rRadio.Config.UI.Icons.settings)
    settings.DoClick = function()
        -- Show settings panel
    end
    self:AddComponent("settings", settings)

    -- Close button
    local close = vgui.Create("DImageButton", header)
    close:SetSize(16, 16)
    close:Dock(RIGHT)
    close:DockMargin(5, 12, 5, 12)
    close:SetImage(rRadio.Config.UI.Icons.close)
    close.DoClick = function()
        if IsValid(activeMenu) then
            activeMenu:Remove()
            activeMenu = nil
        end
    end
    
    self:AddComponent("header", header)
    return header
end

function MENU:CreateSearchBar()
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
    print("[rRadio] Creating radio list") -- Debug
    self.radioList = rRadio.UI.Create("RadioList", self)
    self.radioList:Dock(FILL)
    self.radioList:DockMargin(10, 5, 10, 5)
    self.radioList.Entity = self.Entity -- Pass entity reference
    
    self:AddComponent("list", self.radioList)
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

function MENU:AddComponent(name, component)
    self.components[name] = component
end

function MENU:OnCountrySelected(country)
    -- Update title immediately
    if self.components.header then
        self.components.header:SetTitle(country)
    end
    
    -- Show loading state in controls
    if self.components.controls then
        self.components.controls:SetEnabled(false)
    end
    
    -- Load stations
    if self.components.list then
        self.components.list:LoadStations(country)
    end
    
    -- Re-enable controls after loading
    timer.Simple(0.1, function()
        if IsValid(self) and self.components.controls then
            self.components.controls:SetEnabled(true)
        end
    end)
end

function MENU:OnStationSelected(name, url)
    -- Update title
    if self.components.header then
        self.components.header:SetTitle(name)
    end
    
    -- Enable controls
    if self.components.controls then
        self.components.controls:SetEnabled(true)
        
        -- Update stop button functionality
        local stopBtn = self.components.controls:GetChild(0)  -- First child is stop button
        if IsValid(stopBtn) then
            stopBtn.DoClick = function()
                net.Start("rRadio_SelectStation")
                    net.WriteEntity(self.Entity)
                    net.WriteString("")  -- Empty name indicates stop
                    net.WriteString("")  -- Empty URL indicates stop
                net.SendToServer()
            end
        end
    end
end

rRadio.UI.RegisterPanel("Menu", MENU, "rRadio_Frame")