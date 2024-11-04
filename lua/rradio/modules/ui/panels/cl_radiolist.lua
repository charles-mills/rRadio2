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

    -- Track active items
    self.activeItems = {}

    -- Start with country list
    self:LoadCountries()
end

function RADIO_LIST:CleanupPanels()
    -- Remove all active items
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

function RADIO_LIST:OnRemove()
    self:CleanupPanels()
    if self.BaseClass.OnRemove then
        self.BaseClass.OnRemove(self)
    end
end

function RADIO_LIST:CreateListItems(items, batchSize)
    batchSize = batchSize or 50
    local currentBatch = 0
    
    local function createNextBatch()
        local endIndex = math.min(currentBatch + batchSize, #items)
        
        for i = currentBatch + 1, endIndex do
            if not IsValid(self) then return end
            
            local item = self:CreateListItem(items[i])
            if IsValid(item) then
                table.insert(self.activeItems, item)
            end
        end
        
        currentBatch = endIndex
        
        -- Continue with next batch if needed
        if currentBatch < #items then
            timer.Simple(0, createNextBatch)
        else
            -- Final layout update
            timer.Simple(0.1, function()
                if IsValid(self) and IsValid(self.listContainer) then
                    self.listContainer:InvalidateLayout(true)
                    self.scroll:InvalidateLayout(true)
                end
            end)
        end
    end
    
    -- Start first batch
    createNextBatch()
end

function RADIO_LIST:LoadCountries()
    print("[rRadio] RadioList: Loading countries...")
    self.mode = "country"
    
    -- Cleanup existing panels
    self:CleanupPanels()
    
    -- Prepare items to create
    local itemsToCreate = {}
    
    -- Add favorites section
    if #rRadio.Favorites.Countries > 0 then
        table.insert(itemsToCreate, {
            name = "Favorite Countries",
            isHeader = true,
            favorite = true
        })
        
        for _, country in ipairs(rRadio.Favorites.Countries) do
            table.insert(itemsToCreate, {
                name = country,
                favorite = true
            })
        end
    end
    
    -- Add regular countries
    local countries = {}
    for countryCode, _ in pairs(rRadio.StationManager.Data.Countries) do
        table.insert(countries, countryCode)
    end
    table.sort(countries)
    
    for _, countryCode in ipairs(countries) do
        if not rRadio.Favorites:IsCountryFavorite(countryCode) then
            table.insert(itemsToCreate, {
                name = countryCode,
                favorite = false
            })
        end
    end
    
    -- Create items in batches
    self:CreateListItems(itemsToCreate)
end

function RADIO_LIST:LoadStations(country)
    print("[rRadio] RadioList: Loading stations for", country)
    self.mode = "station"
    
    -- Cleanup existing panels
    self:CleanupPanels()
    
    local stations = rRadio.StationManager:GetCountryStations(country)
    if not stations then return end
    
    -- Prepare items to create
    local itemsToCreate = {}
    for _, station in ipairs(stations) do
        if station.name and station.url then
            table.insert(itemsToCreate, {
                name = station.name,
                url = station.url,
                favorite = rRadio.Favorites:IsStationFavorite(station.url)
            })
        end
    end
    
    -- Create items in batches
    self:CreateListItems(itemsToCreate)
end

function RADIO_LIST:SetEntity(ent)
    self.Entity = ent
    print("[rRadio] RadioList SetEntity:", tostring(self.Entity))
end

function RADIO_LIST:FilterItems(searchText)
    searchText = string.lower(searchText or "")
    
    -- If search is empty, show all items
    if searchText == "" then
        for _, item in pairs(self.activeItems) do
            if IsValid(item) then
                item:SetVisible(true)
            end
        end
        self.listContainer:InvalidateLayout()
        return
    end
    
    -- Filter items based on search text
    for _, item in pairs(self.activeItems) do
        if IsValid(item) then
            local name = string.lower(item.displayName or "")
            local visible = string.find(name, searchText, 1, true)
            item:SetVisible(visible)
        end
    end
    
    -- Update layout
    self.listContainer:InvalidateLayout()
end

function RADIO_LIST:CreateListItem(data)
    local item = vgui.Create("DButton", self.listContainer)
    item:Dock(TOP)
    item:SetTall(40)
    item:DockMargin(0, 0, 0, 2)
    item:SetText("")
    
    -- Store data and display name for searching
    item.data = data
    item.displayName = data.isHeader and data.name or rRadio.Utils.FormatName(data.name)
    
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
                print("[rRadio] Selected country:", data.name)
                self:GetParent():OnCountrySelected(data.name)
            end
        else
            if data.url then
                print("[rRadio] Attempting to play station:", data.name, data.url)
                print("[rRadio] RadioList Entity:", tostring(self.Entity))
                print("[rRadio] Parent Entity:", tostring(self:GetParent().Entity))
                
                local targetEntity = self.Entity or self:GetParent().Entity
                
                if not IsValid(targetEntity) then
                    print("[rRadio] Error: Invalid entity reference")
                    return
                end
                
                -- Send station selection to server
                net.Start("rRadio_SelectStation")
                    net.WriteEntity(targetEntity)
                    net.WriteString(data.name)
                    net.WriteString(data.url)
                net.SendToServer()
                
                print("[rRadio] Sent station selection to server for entity:", tostring(targetEntity))
            end
        end
    end
    
    return item
end

rRadio.UI.RegisterPanel("RadioList", RADIO_LIST, "rRadio_ThemePanel")