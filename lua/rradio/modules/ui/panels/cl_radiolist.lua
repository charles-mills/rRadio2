local RADIO_LIST = {}

function RADIO_LIST:Init()
    self.BaseClass.Init(self)
    
    -- Initialize theme colors
    self.themeColors = {
        background = self:GetThemeColor("background"),
        item = self:GetThemeColor("item"),
        itemHover = self:GetThemeColor("item_hover"),
        text = self:GetThemeColor("text"),
        accent = self:GetThemeColor("accent"),
        favorite = self:GetThemeColor("favorite")
    }
    
    -- Create scrollable container
    self.scroll = vgui.Create("DScrollPanel", self)
    self.scroll:Dock(FILL)
    self.scroll:DockMargin(0, 0, 4, 0)
    
    -- Style scrollbar
    local sbar = self.scroll:GetVBar()
    sbar:SetWide(4)
    sbar:SetHideButtons(true)
    sbar:DockMargin(2, 2, 2, 2)
    
    sbar.Paint = function(_, w, h)
        draw.RoundedBox(2, 0, 0, w, h, self.themeColors.background)
    end
    
    sbar.btnGrip.Paint = function(_, w, h)
        draw.RoundedBox(2, 0, 0, w, h, self.themeColors.accent)
    end

    -- Create list container
    self.listContainer = vgui.Create("DListLayout", self.scroll)
    self.listContainer:Dock(TOP)
    self.listContainer:DockMargin(5, 5, 5, 5)
    self.listContainer.Paint = function() end

    -- Start with country list
    self:LoadCountries()
end

function RADIO_LIST:LoadCountries()
    print("[rRadio] RadioList: Loading countries...")
    self.mode = "country"
    self.listContainer:Clear()
    
    -- Get sorted list of countries
    local countries = {}
    for countryCode, data in pairs(rRadio.StationManager.Data.Countries) do
        table.insert(countries, countryCode)
    end
    table.sort(countries)
    
    print("[rRadio] RadioList: Found " .. #countries .. " countries")
    
    -- Add favorites section at top if any exist
    if #rRadio.Favorites.Countries > 0 then
        self:CreateListItem({
            name = "Favorite Countries",
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
    
    -- Add all other countries
    for _, countryCode in ipairs(countries) do
        if not rRadio.Favorites:IsCountryFavorite(countryCode) then
            local item = self:CreateListItem({
                name = countryCode,
                favorite = false
            })
            print("[rRadio] RadioList: Added country " .. countryCode)
        end
    end

    -- Force layout update
    self.listContainer:InvalidateLayout(true)
    self.scroll:InvalidateLayout(true)
end

function RADIO_LIST:CreateListItem(data)
    local item = vgui.Create("DButton", self.listContainer)
    item:SetTall(40)
    item:DockMargin(0, 0, 0, 2)
    item:SetText("")
    item:Dock(TOP)
    
    -- Store data
    item.data = data
    item.displayName = rRadio.Utils.FormatName(data.name)
    
    item.Paint = function(s, w, h)
        -- Background with hover effect
        local bgColor = s:IsHovered() and self.themeColors.itemHover or self.themeColors.item
        draw.RoundedBox(6, 0, 0, w, h, bgColor)
        
        -- Star icon
        surface.SetDrawColor(255, 255, 255, data.favorite and 255 or 100)
        surface.SetMaterial(Material(data.favorite and 
            rRadio.Config.UI.Icons.favorite_filled or 
            rRadio.Config.UI.Icons.favorite))
        surface.DrawTexturedRect(10, h/2-8, 16, 16)
        
        -- Name
        draw.SimpleText(item.displayName, 
            self:CreateScaledFont("Item", 16),
            40, h/2, self.themeColors.text,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Handle clicking
    item.DoClick = function()
        if self.mode == "country" then
            if self:GetParent() and self:GetParent().OnCountrySelected then
                self:GetParent():OnCountrySelected(data.name)
            end
        else
            if data.url then
                -- Send station selection to server
                net.Start("rRadio_SelectStation")
                    net.WriteEntity(self.Entity)
                    net.WriteString(data.name)
                    net.WriteString(data.url)
                net.SendToServer()
                
                -- Update UI
                if self:GetParent() then
                    self:GetParent():OnStationSelected(data.name, data.url)
                end
            end
        end
    end
    
    return item
end

function RADIO_LIST:LoadStations(country)
    self.mode = "station"
    self.listContainer:Clear()
    
    local stations = rRadio.StationManager:GetCountryStations(country)
    if not stations then return end
    
    for _, station in ipairs(stations) do
        if station.name and station.url then
            self:CreateListItem({
                name = station.name,
                url = station.url,
                favorite = rRadio.Favorites:IsStationFavorite(station.url)
            })
        end
    end
end

rRadio.UI.RegisterPanel("RadioList", RADIO_LIST, "rRadio_ThemePanel")