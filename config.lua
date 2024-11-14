function love.conf(t)
    t.window.title = "Wator"  
    t.window.width = 800                   
    t.window.height = 600                   
    
    -- Optional but recommended settings
    t.version = "11.4"                       -- The LÖVE version this game was made for
    t.console = true                         -- Enable console output for Windows
    
    -- You can disable unused modules to save memory
    t.modules.joystick = false
    t.modules.physics = false