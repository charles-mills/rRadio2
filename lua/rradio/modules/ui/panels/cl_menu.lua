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
    
    -- Initialize theme colors
    self.themeColors = {
        background = rRadio.Theme:GetColor("background"),
        foreground = rRadio.Theme:GetColor("foreground"),
        header = rRadio.Theme:GetColor("header"),
        item = rRadio.Theme:GetColor("item"),
        item_hover = rRadio.Theme:GetColor("item_hover"),
        text = rRadio.Theme:GetColor("text"),
        accent = rRadio.Theme:GetColor("accent"),
        error = rRadio.Theme:GetColor("error"),
        favorite = rRadio.Theme:GetColor("favorite")
    }
    
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
    self:CreateHeader()
    self:CreateSearch()
    self:CreateRadioList()
    self:CreateControls()
end

function MENU:CreateRadioList()
    local list = rRadio.UI.Create("RadioList", self)
    list:Dock(FILL)
    list:DockMargin(10, 5, 10, 5)
    list.Entity = self.Entity
    
    self:AddComponent("list", list)
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

function MENU:CreateHeader()
    local header = vgui.Create("DPanel", self)
    header:Dock(TOP)
    header:SetTall(50)
    header.Paint = function(s, w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, self.themeColors.header, true, true, false, false)
    end

    -- Radio icon and title
    local title = vgui.Create("DPanel", header)
    title:Dock(LEFT)
    title:SetWide(200)
    title:DockMargin(15, 0, 0, 0)
    title.Paint = function(s, w, h)
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(rRadio.Utils.GetIcon("radio"))
        surface.DrawTexturedRect(0, h/2-10, 20, 20)
        
        draw.SimpleText(self.currentTitle or "Select a Country", 
            self:CreateScaledFont("Title", 20),
            30, h/2, self.themeColors.text,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Right-side buttons container
    local btnContainer = vgui.Create("DPanel", header)
    btnContainer:Dock(RIGHT)
    btnContainer:SetWide(95) -- Increased width for back button
    btnContainer:DockMargin(0, 0, 10, 0)
    btnContainer.Paint = function() end

    -- Back button (hidden by default)
    self.backButton = vgui.Create("DImageButton", btnContainer)
    self.backButton:SetSize(20, 20)
    self.backButton:Dock(LEFT)
    self.backButton:DockMargin(5, 15, 5, 15)
    self.backButton:SetMaterial(rRadio.Utils.GetIcon("back"))
    self.backButton:SetVisible(false)
    self.backButton.DoClick = function()
        self:GoBack()
    end

    -- Settings button (admin only)
    if LocalPlayer():IsAdmin() then
        local settings = vgui.Create("DImageButton", btnContainer)
        settings:SetSize(20, 20)
        settings:Dock(LEFT)
        settings:DockMargin(5, 15, 5, 15)
        settings:SetMaterial(rRadio.Utils.GetIcon("settings"))
    end

    -- Close button
    local close = vgui.Create("DImageButton", btnContainer)
    close:SetSize(20, 20)
    close:Dock(RIGHT)
    close:DockMargin(5, 15, 5, 15)
    close:SetMaterial(rRadio.Utils.GetIcon("close"))
    close.DoClick = function() self:Remove() end

    self:AddComponent("header", header)
    return header
end

function MENU:GoBack()
    if self.currentView == "stations" then
        -- Update title
        self.currentTitle = "Select a Country"
        
        -- Hide back button
        if IsValid(self.backButton) then
            self.backButton:SetVisible(false)
        end
        
        -- Reset search
        if self.components.search then
            self.components.search:SetText("")
        end
        
        -- Show country list
        if self.components.list then
            self.components.list:LoadCountries()
        end
        
        self.currentView = "countries"
    end
end

function MENU:OnCountrySelected(country)
    -- Update title
    self.currentTitle = rRadio.Utils.FormatCountryName(country)
    
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

function MENU:CreateSearch()
    local search = vgui.Create("DTextEntry", self)
    search:Dock(TOP)
    search:DockMargin(15, 15, 15, 10)
    search:SetTall(35)
    search:SetFont(self:CreateScaledFont("Item", 16))
    search:SetPlaceholderText("Search...")
    search:SetTextColor(self.themeColors.text)
    search.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, self.themeColors.item)
        s:DrawTextEntryText(
            self.themeColors.text,
            self.themeColors.accent,
            self.themeColors.text
        )
    end
end

function MENU:CreateControls()
    local controls = vgui.Create("DPanel", self)
    controls:Dock(BOTTOM)
    controls:SetTall(60)
    controls:DockMargin(15, 5, 15, 15)
    controls.Paint = function() end

    -- Stop button
    local stop = vgui.Create("DButton", controls)
    stop:Dock(LEFT)
    stop:SetWide(80)
    stop:SetText("STOP")
    stop:SetFont(self:CreateScaledFont("Button", 16))
    stop.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, 
            s:IsHovered() and self.themeColors.error or self.themeColors.item)
    end

    -- Volume control
    local volume = vgui.Create("DPanel", controls)
    volume:Dock(FILL)
    volume:DockMargin(15, 0, 0, 0)
    volume.Paint = function(s, w, h)
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(rRadio.Utils.GetIcon("volume"))
        surface.DrawTexturedRect(0, h/2-10, 20, 20)
        
        local sliderWidth = w - 35
        draw.RoundedBox(4, 30, h/2-2, sliderWidth, 4, self.themeColors.item)
        draw.RoundedBox(4, 30, h/2-2, sliderWidth * 0.75, 4, self.themeColors.accent)
    end
end

function MENU:AddComponent(name, component)
    self.components[name] = component
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