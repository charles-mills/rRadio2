rRadio.Theme = {
    Current = "dark",
    Themes = {},
    AnimatedColors = {},

    -- Theme registration
    RegisterTheme = function(self, name, data)
        if not data.colors then return false end
        
        self.Themes[name] = {
            name = name,
            author = data.author or "Unknown",
            description = data.description or "",
            colors = data.colors
        }
        
        hook.Run("rRadio_ThemeRegistered", name, data)
        return true
    end,

    -- Theme management
    SetTheme = function(self, name)
        if not self.Themes[name] then return false end
        
        self.Current = name
        file.Write("rradio/theme.txt", name)
        hook.Run("rRadio_ThemeChanged", name, self.Themes[name])
        return true
    end,

    GetTheme = function(self, name)
        return self.Themes[name]
    end,

    GetAllThemes = function(self)
        local themes = {}
        for name, data in pairs(self.Themes) do
            table.insert(themes, {
                name = name,
                author = data.author,
                description = data.description
            })
        end
        return themes
    end,

    -- Color management
    GetColor = function(self, key, alpha)
        local theme = self.Themes[self.Current]
        if not theme then return color_white end
        
        local col = theme.colors[key]
        if not col then 
            print("[rRadio] Warning: Missing theme color", key)
            return color_white 
        end
        
        if alpha then
            return Color(col.r, col.g, col.b, alpha)
        end
        return col
    end,

    -- Color animation
    LerpColor = function(self, identifier, targetColor, duration)
        local animData = self.AnimatedColors[identifier]
        if not animData then
            self.AnimatedColors[identifier] = {
                current = targetColor,
                target = targetColor,
                startTime = 0,
                duration = 0
            }
            return targetColor
        end

        if animData.target != targetColor then
            animData.start = animData.current
            animData.target = targetColor
            animData.startTime = SysTime()
            animData.duration = duration or rRadio.Config.UI.AnimationSpeed
        end

        local fraction = math.Clamp((SysTime() - animData.startTime) / animData.duration, 0, 1)
        animData.current = Color(
            Lerp(fraction, animData.start.r, animData.target.r),
            Lerp(fraction, animData.start.g, animData.target.g),
            Lerp(fraction, animData.start.b, animData.target.b),
            Lerp(fraction, animData.start.a, animData.target.a)
        )

        return animData.current
    end,

    Initialize = function(self)
        -- Create data directory
        if not file.Exists("rradio", "DATA") then
            file.CreateDir("rradio")
        end

        -- Register default themes
        self:RegisterTheme("dark", {
            author = "rRadio",
            description = "Default dark theme",
            colors = {
                background = Color(13, 13, 13, 250),
                foreground = Color(18, 18, 18, 250),
                header = Color(15, 15, 15, 250),
                item = Color(24, 24, 24, 250),
                item_hover = Color(32, 32, 32, 250),
                accent = Color(65, 105, 225),
                text = Color(255, 255, 255),
                text_dark = Color(180, 180, 180),
                success = Color(46, 204, 113),
                error = Color(231, 76, 60),
                favorite = Color(255, 215, 0),
                separator = Color(40, 40, 40)
            }
        })

        self:RegisterTheme("light", {
            author = "rRadio",
            description = "Clean light theme",
            colors = {
                background = Color(240, 240, 240, 245),
                foreground = Color(230, 230, 230, 245),
                header = Color(220, 220, 220, 245),
                item = Color(220, 220, 220, 245),
                item_hover = Color(210, 210, 210, 245),
                accent = Color(65, 105, 225),
                text = Color(30, 30, 30),
                text_dark = Color(50, 50, 50),
                success = Color(46, 204, 113),
                error = Color(231, 76, 60),
                favorite = Color(255, 215, 0)
            }
        })

        self:RegisterTheme("midnight", {
            author = "rRadio",
            description = "Deep dark theme with blue accents",
            colors = {
                background = Color(13, 17, 23, 245),
                foreground = Color(22, 27, 34, 245),
                header = Color(22, 27, 34, 245),
                item = Color(33, 38, 45, 245),
                item_hover = Color(48, 54, 61, 245),
                accent = Color(88, 166, 255),
                text = Color(255, 255, 255),
                text_dark = Color(139, 148, 158),
                success = Color(46, 160, 67),
                error = Color(248, 81, 73),
                favorite = Color(255, 215, 0)
            }
        })

        -- Load saved theme
        local saved = file.Read("rradio/theme.txt", "DATA")
        if saved and self.Themes[saved] then
            self.Current = saved
        end
    end
}

-- Initialize theme system
rRadio.Theme:Initialize()

-- Allow other addons to register themes
hook.Add("Initialize", "rRadio_LoadCustomThemes", function()
    hook.Run("rRadio_RegisterThemes")
end) 