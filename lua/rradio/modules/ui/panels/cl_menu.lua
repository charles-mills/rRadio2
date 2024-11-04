-- Single menu instance tracking
local activeMenu = nil

-- Network handler for opening the menu
net.Receive("rRadio_OpenInterface", function()
    local ent = net.ReadEntity()
    print("[rRadio] Opening interface for entity:", tostring(ent))
    
    if not IsValid(ent) then 
        print("[rRadio] Error: Invalid entity received")
        return 
    end
    
    -- Check if menu can open
    if rRadio.Hooks.PreMenuOpen(ent) == false then
        print("[rRadio] Menu opening prevented by hook")
        return
    end
    
    -- Remove existing menu if it exists
    if IsValid(activeMenu) then
        if rRadio.Hooks.PreMenuClose(activeMenu) == false then
            return
        end
        activeMenu:Remove()
        rRadio.Hooks.PostMenuClose(activeMenu)
        activeMenu = nil
    end
    
    -- Create new menu
    activeMenu = rRadio.UI.Create("Menu")
    activeMenu:SetEntity(ent)
    
    -- Call post-open hook
    rRadio.Hooks.PostMenuOpen(ent, activeMenu)
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
    
    -- Track active components and current view
    self.components = {}
    self.currentView = "countries" -- Track current view for back button
    
    -- Create components
    self:CreateTitleBar()
    self:CreateSearchBar()
    self:CreateList()
    self:CreateControls()
end

function MENU:SetEntity(ent)
    self.Entity = ent
    -- Update entity reference in components
    if self.components.list then
        self.components.list.Entity = ent
    end
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

    -- Back button (hidden by default)
    self.backButton = vgui.Create("DImageButton", header)
    self.backButton:SetSize(16, 16)
    self.backButton:Dock(LEFT)
    self.backButton:DockMargin(5, 12, 5, 12)
    self.backButton:SetImage(rRadio.Config.UI.Icons.back)
    self.backButton:SetVisible(false)
    self.backButton.DoClick = function()
        self:GoBack()
    end

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
        title:SetText(text)
        title:SizeToContents()
    end

    -- Settings and close buttons
    if LocalPlayer():IsAdmin() then
        local settings = vgui.Create("DImageButton", header)
        settings:SetSize(16, 16)
        settings:Dock(RIGHT)
        settings:DockMargin(5, 12, 5, 12)
        settings:SetImage(rRadio.Config.UI.Icons.settings)
        self:AddComponent("settings", settings)
    end

    local close = vgui.Create("DImageButton", header)
    close:SetSize(16, 16)
    close:Dock(RIGHT)
    close:DockMargin(5, 12, 5, 12)
    close:SetImage(rRadio.Config.UI.Icons.close)
    close.DoClick = function() self:Remove() end
    
    self:AddComponent("header", header)
end

function MENU:GoBack()
    if self.currentView == "stations" then
        -- Reset search
        if self.components.search then
            self.components.search:SetText("")
        end
        
        -- Update title and view
        if self.components.header then
            self.components.header:SetTitle("Select a Country")
        end
        
        -- Hide back button
        if IsValid(self.backButton) then
            self.backButton:SetVisible(false)
        end
        
        -- Show country list
        if self.components.list then
            self.components.list:LoadCountries()
        end
        
        self.currentView = "countries"
    end
end

function MENU:CreateSearchBar()
    local search = vgui.Create("DTextEntry", self)
    search:Dock(TOP)
    search:DockMargin(10, 5, 10, 5)
    search:SetTall(30)
    search:SetFont(self:CreateScaledFont("Search", 16))
    search:SetPlaceholderText("Search...")
    
    -- Add search functionality
    search.OnChange = function(s)
        if self.components.list then
            self.components.list:FilterItems(s:GetText())
        end
    end
    
    self:AddComponent("search", search)
end

function MENU:CreateList()
    local list = rRadio.UI.Create("RadioList", self)
    list:Dock(FILL)
    list:DockMargin(10, 5, 10, 5)
    list.Entity = self.Entity -- Pass entity reference
    
    print("[rRadio] Creating list - Entity:", tostring(list.Entity))
    
    self:AddComponent("list", list)
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
    -- Update title
    if self.components.header then
        self.components.header:SetTitle(country)
    end
    
    -- Show back button
    if IsValid(self.backButton) then
        self.backButton:SetVisible(true)
    end
    
    -- Reset search
    if self.components.search then
        self.components.search:SetText("")
    end
    
    -- Load stations
    if self.components.list then
        self.components.list:LoadStations(country)
    end
    
    self.currentView = "stations"
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

-- In the menu's Remove function
function MENU:Remove()
    if rRadio.Hooks.PreMenuClose(self) == false then
        return
    end
    
    self.BaseClass.Remove(self)
    rRadio.Hooks.PostMenuClose(self)
end

rRadio.UI.RegisterPanel("Menu", MENU, "rRadio_Frame")