TBOI.ROOMS = {}

--Treasure Room
TBOI.ROOMS.TREASURE_ROOM = function()
        if not G.treasure_room then
            G.GAME.joker_max.treasure = 1
            G.treasure_room = CardArea(
                G.hand.T.x+0,
                G.hand.T.y+G.ROOM.T.y + 9,
                3.15 * G.CARD_W, 
                1.05 * G.CARD_H, 
                {card_limit = G.GAME.joker_max.treasure or 1, type = 'shop', highlight_limit = 1}
            )
            TBOI.restore_tab_area('treasure', G.treasure_room)
        end
        G.GAME.planetarium_text = G.GAME.planetarium_text or { prefix = "", number = "", flavour = "" }
        local choices = (G.GAME and G.GAME.choices and G.GAME.choices['treasure'] and (G.GAME.choices['treasure'] + 1)) or 0
        
        if choices > 0 then
            G.GAME.planetarium_text.prefix = "Choices Left: "
            G.GAME.planetarium_text.number = tostring(choices)
            G.GAME.planetarium_text.flavour = ""
        else
            G.GAME.planetarium_text.prefix = ""
            G.GAME.planetarium_text.number = ""
            G.GAME.planetarium_text.flavour = localize("tboi_treasure_flavour")
        end

        return {n=G.UIT.C, config={id = 'treasure', align = "cm", padding = 0.1, emboss = 0.05, r = 0.1, colour = G.C.DYN_UI.BOSS_MAIN}, nodes={
            {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
                {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.L_BLACK, emboss = 0.05, minw = 8.2}, nodes={
                    {n=G.UIT.C, config={align = "cm"}, nodes={
                        {n=G.UIT.O, config={object = G.treasure_room}},
                    }}
                }},
            }},
            {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes = {
                {n = G.UIT.T, config = {ref_table = G.GAME.planetarium_text, ref_value = 'prefix', colour = G.C.UI.TEXT_LIGHT, scale = 0.5}},
                {n = G.UIT.T, config = {ref_table = G.GAME.planetarium_text, ref_value = 'number', colour = G.C.FILTER, scale = 0.5}},
                {n = G.UIT.T, config = {ref_table = G.GAME.planetarium_text, ref_value = 'flavour', colour = G.C.UI.TEXT_LIGHT, scale = 0.5}}
            }}
        }}
    end
--Planetarium
TBOI.ROOMS.PLANETARIUM = function()
        if not G.planetarium then
            G.planetarium = CardArea(
                G.hand.T.x+0,
                G.hand.T.y+G.ROOM.T.y + 9,
                3.15 * G.CARD_W, 
                1.05 * G.CARD_H, 
                {card_limit = G.GAME.joker_max.planetarium or 1, type = 'shop', highlight_limit = 1}
            )
            -- NUOVO: come sopra, ripristina dai dati salvati se esistono.
            TBOI.restore_tab_area('planetarium', G.planetarium)
        end
        G.GAME.planetarium_text = G.GAME.planetarium_text or { prefix = "", number = "", flavour = "" }
        local choices = (G.GAME and G.GAME.choices and G.GAME.choices['planetarium'] and (G.GAME.choices['planetarium'] + 1)) or 0
        
        if choices > 0 then
            G.GAME.planetarium_text.prefix = "Choices Left: "
            G.GAME.planetarium_text.number = tostring(choices)
            G.GAME.planetarium_text.flavour = ""
        else
            G.GAME.planetarium_text.prefix = ""
            G.GAME.planetarium_text.number = ""
            G.GAME.planetarium_text.flavour = localize("tboi_treasure_flavour")
        end

        return {n=G.UIT.C, config={id = 'planetarium', align = "cm", padding = 0.1, emboss = 0.05, r = 0.1, colour = lighten(G.C.SET.Planet,0.5)}, nodes={
            {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
                {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.SET.Planet, emboss = 0.05, minw = 8.2}, nodes={
                    {n=G.UIT.C, config={align = "cm"}, nodes={
                        {n=G.UIT.O, config={object = G.planetarium}},
                    }}
                }},
            }},
            {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes = {
                {n = G.UIT.T, config = {ref_table = G.GAME.planetarium_text, ref_value = 'prefix', colour = G.C.UI.TEXT_LIGHT, scale = 0.5}},
                {n = G.UIT.T, config = {ref_table = G.GAME.planetarium_text, ref_value = 'number', colour = G.C.FILTER, scale = 0.5}},
                {n = G.UIT.T, config = {ref_table = G.GAME.planetarium_text, ref_value = 'flavour', colour = G.C.UI.TEXT_LIGHT, scale = 0.5}}
            }}
        }}
    end