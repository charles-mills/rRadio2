local RADIO_LIST = {}

function RADIO_LIST:Init()
    self.BaseClass.Init(self)
    
    -- Initialize theme colors
    self.themeColors = {
        background = self:GetThemeColor("background"),
        foreground = self:GetThemeColor("foreground"),
        header = self:GetThemeColor("header"),
        item = self:GetThemeColor("item"),
        item_hover = self:GetThemeColor("item_hover"),
        text = self:GetThemeColor("text"),
        accent = self:GetThemeColor("accent"),
        error = self:GetThemeColor("error"),
        favorite = self:GetThemeColor("favorite"),
        separator = self:GetThemeColor("separator")
    }
    
    -- Create scrollable container
    self.scroll = vgui.Create("DScrollPanel", self)
    self.scroll:Dock(FILL)
    self.scroll:DockMargin(0, 0, 4, 0)
    
    -- Create list container
    self.listContainer = vgui.Create("DListLayout", self.scroll)
    self.listContainer:Dock(TOP)
    self.listContainer:DockMargin(15, 5, 15, 5)
    self.listContainer.Paint = function() end
    
    -- Style scrollbar
    local sbar = self.scroll:GetVBar()
    sbar:SetWide(4)
    sbar:SetHideButtons(true)
    sbar:DockMargin(2, 2, 2, 2)
    
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(_, w, h)
        draw.RoundedBox(2, 0, 0, w, h, self.themeColors.accent)
    end
    
    -- Track active items for cleanup
    self.activeItems = {}
    self.cleanupTimer = "rRadio_ListCleanup_" .. tostring({})
    
    -- Load countries immediately
    self:LoadCountries()
end

function RADIO_LIST:PerformLayout(w, h)
    if IsValid(self.listContainer) then
        self.listContainer:SetWide(w - 8) -- Account for scrollbar
    end
end

function RADIO_LIST:OnRemove()
    if timer.Exists(self.cleanupTimer) then
        timer.Remove(self.cleanupTimer)
    end
    self:CleanupItems()
end

function RADIO_LIST:CleanupItems()
    -- Remove timer if it exists
    if timer.Exists(self.cleanupTimer) then
        timer.Remove(self.cleanupTimer)
    end

    -- Clean up active items
    for _, item in pairs(self.activeItems) do
        if IsValid(item) then
            item:Remove()
        end
    end
    self.activeItems = {}

    -- Clear container
    if IsValid(self.listContainer) then
        self.listContainer:Clear()
    end

    -- Force garbage collection
    collectgarbage("collect")
end

function RADIO_LIST:LoadCountries()
    -- Clean up existing items first
    self:CleanupItems()
    
    self.mode = "country"
    
    -- Get and sort countries
    local countries = {}
    for countryCode, countryData in pairs(rRadio.StationManager.Data.Countries) do
        table.insert(countries, {
            code = countryCode,
            name = countryCode,
            displayName = rRadio.Utils.FormatCountryName(countryCode)
        })
    end
    
    table.sort(countries, function(a, b)
        return a.displayName < b.displayName
    end)
    
    -- Create items in batches to prevent stack overflow
    local itemsToCreate = {}
    
    -- Add favorites section
    if #rRadio.Favorites.Countries > 0 then
        table.insert(itemsToCreate, {
            name = "Favorite Stations",
            displayName = "Favorite Stations",
            isHeader = true,
            favorite = true
        })
        
        for _, countryCode in ipairs(rRadio.Favorites.Countries) do
            table.insert(itemsToCreate, {
                name = countryCode,
                code = countryCode,
                displayName = rRadio.Utils.FormatCountryName(countryCode),
                favorite = true
            })
        end
    end
    
    -- Add regular countries
    for _, country in ipairs(countries) do
        if not rRadio.Favorites:IsCountryFavorite(country.code) then
            table.insert(itemsToCreate, {
                name = country.code,
                code = country.code,
                displayName = country.displayName,
                favorite = false
            })
        end
    end
    
    -- Create items in batches
    local batchSize = 20
    local currentBatch = 0
    
    timer.Create(self.cleanupTimer, 0, math.ceil(#itemsToCreate / batchSize), function()
        if not IsValid(self) then 
            timer.Remove(self.cleanupTimer)
            return 
        end
        
        local startIndex = currentBatch * batchSize + 1
        local endIndex = math.min(startIndex + batchSize - 1, #itemsToCreate)
        
        for i = startIndex, endIndex do
            local item = self:CreateListItem(itemsToCreate[i])
            if IsValid(item) then
                table.insert(self.activeItems, item)
            end
        end
        
        currentBatch = currentBatch + 1
    end)
end

function RADIO_LIST:LoadStations(country)
    -- Clean up existing items first
    self:CleanupItems()
    
    self.mode = "station"
    
    local stations = rRadio.StationManager:GetCountryStations(country)
    if not stations then return end
    
    -- Create items in batches
    local itemsToCreate = {}
    for _, station in ipairs(stations) do
        if station.name and station.url then
            table.insert(itemsToCreate, {
                name = station.name,
                displayName = station.name,
                url = station.url,
                favorite = rRadio.Favorites:IsStationFavorite(station.url)
            })
        end
    end
    
    -- Sort stations
    table.sort(itemsToCreate, function(a, b)
        return a.displayName < b.displayName
    end)
    
    -- Create items in batches
    local batchSize = 20
    local currentBatch = 0
    
    timer.Create(self.cleanupTimer, 0, math.ceil(#itemsToCreate / batchSize), function()
        if not IsValid(self) then 
            timer.Remove(self.cleanupTimer)
            return 
        end
        
        local startIndex = currentBatch * batchSize + 1
        local endIndex = math.min(startIndex + batchSize - 1, #itemsToCreate)
        
        for i = startIndex, endIndex do
            local item = self:CreateListItem(itemsToCreate[i])
            if IsValid(item) then
                table.insert(self.activeItems, item)
            end
        end
        
        currentBatch = currentBatch + 1
    end)
end

function RADIO_LIST:CreateListItem(data)
    local item = vgui.Create("DButton", self.listContainer)
    item:Dock(TOP)
    item:SetTall(45)
    item:DockMargin(0, 0, 0, 2)
    item:SetText("")
    item:SetCursor("hand")
    
    -- Store data
    item.data = data
    item.displayName = data.displayName or data.name
    item.alpha = 0
    item.targetAlpha = 0
    
    -- Hover animation
    item.Think = function(s)
        if s:IsHovered() then
            s.targetAlpha = 1
        else
            s.targetAlpha = 0
        end
        
        s.alpha = Lerp(FrameTime() * 8, s.alpha, s.targetAlpha)
    end
    
    item.Paint = function(s, w, h)
        if data.isSeparator then
            draw.RoundedBox(0, 10, h/2-1, w-20, 2, self.themeColors.separator)
            return
        end
        
        -- Background with hover effect
        local bgColor = self.themeColors.item
        if s:IsHovered() then
            bgColor = rRadio.Utils.LerpColor(s.alpha, self.themeColors.item, self.themeColors.item_hover)
        end
        draw.RoundedBox(6, 0, 0, w, h, bgColor)
        
        if data.isHeader then
            -- Header style
            draw.SimpleText(item.displayName, 
                self:CreateScaledFont("Title", 16, 600),
                10, h/2, self.themeColors.text_dark,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            return
        end
        
        -- Star icon with fade effect
        local starAlpha = data.favorite and 255 or (s:IsHovered() and 100 or 50)
        surface.SetDrawColor(255, 255, 255, starAlpha)
        surface.SetMaterial(data.favorite and 
            rRadio.Utils.GetIcon("favorite_filled") or 
            rRadio.Utils.GetIcon("favorite"))
        surface.DrawTexturedRect(10, h/2-8, 16, 16)
        
        -- Name with proper font and color
        draw.SimpleText(item.displayName, 
            self:CreateScaledFont("Item", 16),
            40, h/2, 
            data.favorite and self.themeColors.favorite or self.themeColors.text,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Handle clicking
    item.DoClick = function(s)
        if s.data.isHeader or s.data.isSeparator then return end
        
        if input.IsMouseDown(MOUSE_RIGHT) then
            s.data.favorite = not s.data.favorite
            if self.mode == "country" then
                rRadio.Favorites:ToggleCountry(s.data.code or s.data.name)
            else
                rRadio.Favorites:ToggleStation(s.data.name, s.data.url)
            end
            return
        end
        
        if self.mode == "country" then
            if self:GetParent() and self:GetParent().OnCountrySelected then
                self:GetParent():OnCountrySelected(s.data.code or s.data.name)
            end
        else
            if s.data.url then
                local targetEntity = self.Entity or self:GetParent().Entity
                if not IsValid(targetEntity) then return end
                
                net.Start("rRadio_SelectStation")
                    net.WriteEntity(targetEntity)
                    net.WriteString(s.data.name)
                    net.WriteString(s.data.url)
                net.SendToServer()
            end
        end
    end
    
    return item
end

function RADIO_LIST:OnCountrySelected(country)
    print("[rRadio] Country selected:", country)
    if self:GetParent() and self:GetParent().OnCountrySelected then
        self:GetParent():OnCountrySelected(country)
    end
end

rRadio.UI.RegisterPanel("RadioList", RADIO_LIST, "rRadio_ThemePanel")