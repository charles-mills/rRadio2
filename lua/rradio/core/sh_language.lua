rRadio.Language = {
    Current = "en",
    Phrases = {
        en = {
            menu_title = "rRadio",
            browse_stations = "Browse Stations",
            favorites = "Favorites",
            settings = "Settings",
            admin_panel = "Admin Panel",
            select_country = "Select Country",
            search_stations = "Search stations...",
            volume = "Volume",
            play = "Play",
            stop = "Stop",
            add_favorite = "Add to Favorites",
            remove_favorite = "Remove from Favorites",
            limit_reached = "Favorites limit reached",
            already_favorite = "Already in favorites"
        }
    },

    Get = function(self, key)
        return self.Phrases[self.Current][key] or key
    end,

    AddLanguage = function(self, lang, phrases)
        self.Phrases[lang] = phrases
        rRadio.CallHook("LanguageAdded", lang, phrases)
    end,

    SetLanguage = function(self, lang)
        if self.Phrases[lang] then
            self.Current = lang
            rRadio.CallHook("LanguageChanged", lang)
            return true
        end
        return false
    end
} 