rRadio.Hooks = {
    -- Menu hooks
    PreMenuOpen = function(ent)
        -- Return false to prevent menu from opening
        return hook.Run("rRadio_PreMenuOpen", ent)
    end,
    
    PostMenuOpen = function(ent, menu)
        hook.Run("rRadio_PostMenuOpen", ent, menu)
    end,
    
    PreMenuClose = function(menu)
        -- Return false to prevent menu from closing
        return hook.Run("rRadio_PreMenuClose", menu)
    end,
    
    PostMenuClose = function(menu)
        hook.Run("rRadio_PostMenuClose", menu)
    end,
    
    -- Stream hooks
    PreStreamStart = function(ent, data)
        -- Return false to prevent stream from starting
        return hook.Run("rRadio_PreStreamStart", ent, data)
    end,
    
    PostStreamStart = function(ent, data)
        hook.Run("rRadio_PostStreamStart", ent, data)
    end,
    
    PreStreamStop = function(ent)
        -- Return false to prevent stream from stopping
        return hook.Run("rRadio_PreStreamStop", ent)
    end,
    
    PostStreamStop = function(ent)
        hook.Run("rRadio_PostStreamStop", ent)
    end,
    
    -- Station hooks
    PreStationSelect = function(ent, name, url)
        -- Return false to prevent station selection
        return hook.Run("rRadio_PreStationSelect", ent, name, url)
    end,
    
    PostStationSelect = function(ent, name, url)
        hook.Run("rRadio_PostStationSelect", ent, name, url)
    end,
    
    -- Favorite hooks
    PreFavoriteAdd = function(type, data)
        -- Return false to prevent favorite from being added
        return hook.Run("rRadio_PreFavoriteAdd", type, data)
    end,
    
    PostFavoriteAdd = function(type, data)
        hook.Run("rRadio_PostFavoriteAdd", type, data)
    end
} 