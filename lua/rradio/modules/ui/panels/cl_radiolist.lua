local RADIO_LIST = {
    baseClass = "rRadio_ThemePanel"
}

function RADIO_LIST:Init()
    self.BaseClass.Init(self)
    
    -- Create scrollable container
    self.scroll = vgui.Create("DScrollPanel", self)
    self.scroll:Dock(FILL)
    
    -- Style scrollbar
    local sbar = self.scroll:GetVBar()
    sbar:SetWide(4)
    sbar:SetHideButtons(true)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(_, w, h)
        draw.RoundedBox(2, 0, 0, w, h, self.themeColors.accent)
    end
end

function RADIO_LIST:InitializeTheme()
    self.themeColors = {
        background = self:GetThemeColor("background"),
        item = self:GetThemeColor("item"),
        itemHover = self:GetThemeColor("item_hover"),
        text = self:GetThemeColor("text"),
        accent = self:GetThemeColor("accent"),
        favorite = self:GetThemeColor("favorite")
    }
end

function RADIO_LIST:CreateListItem(data)
    local btn = vgui.Create("DButton", self.scroll)
    btn:Dock(TOP)
    btn:SetTall(40)
    btn:DockMargin(0, 0, 0, 2)
    btn:SetText("")
    
    -- Store reference to star status
    btn.isFavorite = data.favorite
    
    btn.Paint = function(s, w, h)
        -- Background
        local bgColor = s:IsHovered() and self.themeColors.itemHover or self.themeColors.item
        draw.RoundedBox(6, 0, 0, w, h, bgColor)
        
        -- Star icon
        surface.SetDrawColor(255, 255, 255, btn.isFavorite and 255 or 100)
        surface.SetMaterial(Material(btn.isFavorite and 
            rRadio.Config.UI.Icons.favorite_filled or 
            rRadio.Config.UI.Icons.favorite))
        surface.DrawTexturedRect(10, h/2-8, 16, 16)
        
        -- Item name
        draw.SimpleText(data.name, 
            self:CreateScaledFont("Item", 16),
            40, h/2, self.themeColors.text,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Handle clicking
    btn.DoClick = function()
        if data.isHeader then return end
        
        -- Toggle favorite if right-clicked
        if input.IsMouseDown(MOUSE_RIGHT) then
            btn.isFavorite = not btn.isFavorite
            if self.mode == "country" then
                rRadio.Favorites:ToggleCountry(data.name)
            else
                rRadio.Favorites:ToggleStation(data.name, data.url)
            end
            return
        end
        
        -- Handle selection
        if self.mode == "country" then
            self:OnCountrySelected(data.name)
        else
            self:OnStationSelected(data.name, data.url)
        end
    end
    
    return btn
end

function RADIO_LIST:LoadCountries()
    self.mode = "country"
    self.scroll:Clear()
    
    -- Add favorites section
    if #rRadio.Favorites.Countries > 0 then
        self:CreateListItem({
            name = "Favorite Stations",
            isHeader = true,
            favorite = true
        })
        
        for _, country in ipairs(rRadio.Favorites.Countries) do
            self:CreateListItem({
                name = country,
                favorite = true
            })
        end
    end
    
    -- Add all countries
    local countries = rRadio.StationManager:GetAllCountries()
    for _, country in ipairs(countries) do
        if not table.HasValue(rRadio.Favorites.Countries, country) then
            self:CreateListItem({
                name = country,
                favorite = false
            })
        end
    end
end

function RADIO_LIST:LoadStations(country)
    self.mode = "station"
    self.scroll:Clear()
    
    local stations = rRadio.StationManager:GetCountryStations(country)
    if not stations then return end
    
    for _, station in ipairs(stations) do
        if station.n and station.u then
            self:CreateListItem({
                name = station.n,
                url = station.u,
                favorite = rRadio.Favorites:IsStationFavorite(station.u)
            })
        end
    end
end

function RADIO_LIST:OnCountrySelected(country)
    if self:GetParent().OnCountrySelected then
        self:GetParent():OnCountrySelected(country)
    end
end

function RADIO_LIST:OnStationSelected(name, url)
    if IsValid(self:GetParent().Entity) then
        net.Start("rRadio_SelectStation")
            net.WriteEntity(self:GetParent().Entity)
            net.WriteString(name)
            net.WriteString(url)
        net.SendToServer()
    end
end

rRadio.UI.RegisterThemePanel("RadioList", RADIO_LIST) 