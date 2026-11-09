TBOI.custom_shop_tabs = {}

--- Serializza il contenuto della CardArea di una pagina (solo chiave ed
--- eventuale edizione di ogni carta) e lo salva in G.GAME, cosicché
--- sopravviva anche a un salvataggio/ricarica della partita.
function TBOI.save_tab_area(tab_name)
    local global_name = TBOI.tab_area_globals[tab_name]
    if not global_name then return end -- non è una pagina con una CardArea propria (es. il negozio vanilla)

    local area = G[global_name]
    if not area then return end

    local saved = {}
    for _, card in ipairs(area.cards) do
        -- Le carte in distruzione (es. sostituite dal D6) non vanno salvate
        if not (card.getting_sliced or card.destroyed or card.removed) then
        table.insert(saved, {
            key = card.config.center.key,
            edition = card.edition and card.edition.type or nil,
            cycle = card.ability and card.ability.tboi_cycle and copy_table(card.ability.tboi_cycle) or nil,
            -- Aggiungi qui altri campi se ti servono (seal, eternal, perishable...)
        })
        end
    end

    G.GAME.tboi_shop_state.saved_areas = G.GAME.tboi_shop_state.saved_areas or {}
    G.GAME.tboi_shop_state.saved_areas[tab_name] = saved
end

--- Salva (vedi sopra) e poi distrugge la CardArea di una pagina non più
--- visibile, azzerando il riferimento globale (es. G.treasure_room = nil)
--- così non resta accessibile/in memoria mentre non è sullo schermo.
function TBOI.unload_tab_area(tab_name)
    local global_name = TBOI.tab_area_globals[tab_name]
    if not global_name then return end

    local area = G[global_name]
    if not area then return end

    TBOI.save_tab_area(tab_name)

    area:remove()
    G[global_name] = nil
end

--- Ricostruisce le carte di una pagina dentro 'area' a partire dai dati
--- salvati in precedenza. Va chiamata SOLO quando l'area è appena stata
--- creata vuota (dentro il rispettivo ui_func, subito dopo la creazione
--- della CardArea) — non nel caso "prima visita in assoluto", in cui invece
--- deve restare vuota e farsi riempire da enter_tab().
--- Ritorna true se ha effettivamente ripristinato qualcosa.
function TBOI.restore_tab_area(tab_name, area)
    local saved = G.GAME.tboi_shop_state.saved_areas and G.GAME.tboi_shop_state.saved_areas[tab_name]
    if not saved then return false end

    for _, card_data in ipairs(saved) do
        local new_card = TBOI.FUNCS.gen_item_in_shop({
            key = card_data.key,
            area = area,
            buy_type = 'select',
        })
        -- create_card tira un'edizione casuale: va sempre sovrascritta con quella salvata,
        -- anche quando la carta salvata non ne aveva (set_edition(nil) la toglie)
        if new_card then
            new_card:set_edition(card_data.edition and ('e_' .. card_data.edition) or nil, true, true)
        end
        -- La carta è nuova: senza questo cycle_options le genererebbe un ciclo diverso
        if new_card and card_data.cycle then
            new_card:restore_cycle(card_data.cycle)
        end
    end

    return true
end

--- Blueprint of a new shop tab, used in new_shops.
--- @param tab_name string ID of the tab
--- @param sprite_pos_x integer X column of the spritesheet
--- @param bg_color table? Background color {r, g, b, a}
--- @param condition_func function Determins when the tab does appear
--- @param unlock_action function? Determins the action of when the tab button is clicked while the shop is not accessable [nil : always open, function : check how to open]
--- @param ui_func function function that returns a UIDEF table
function new_tab(tab_name, sprite_pos_x, bg_color, condition_func, unlock_action, ui_func)
    TBOI.custom_shop_tabs[tab_name] = {
        name = tab_name,
        sprite_pos_x = sprite_pos_x,
        color = bg_color,
        can_enter = condition_func or function() return true end,
        unlock_action = unlock_action,
        ui_func = ui_func
    }
end

--- Base for all new tab shops, to be filled with new_tab functions
function new_shops()
   -- Standard Shop
    new_tab("tboi_main_shop_body", 0, nil, function() return true end, nil, function()
        return get_vanilla_shop_ui()
    end)

    -- Treasure Room
    new_tab("treasure", 1, {0.75, 0.6, 0.2, 1},
    function() 
        return (G.GAME.round_resets.ante or 0) <= 6
    end,
    function()
        if TBOI.FUNCS.can_spend('keys', 1) then
            TBOI.FUNCS.ease_keys(-1)
            return true
        end
        attention_text({text = "Not enough keys!", colour = G.C.RED, scale = 0.5, shadow = true})
        return false
    end,
    TBOI.ROOMS.TREASURE_ROOM
    )
    -- Planetarium
    new_tab("planetarium", 2, {new_colour = darken(G.C.BLUE, 0.4), special_colour = G.C.SET.Planet, tertiary_colour = G.C.BLACK,contrast = 2.5},
    function()
        -- Una volta visitato resta disponibile fino al cambio di ante (ease_ante azzera visited)
        if G.GAME.tboi_shop_state.visited['planetarium'] then return true end
        local ante = G.GAME.round_resets.ante or 0
        if ante > 6 then return false end
        -- Il tiro si fa una volta per ante e si salva: questa funzione viene chiamata a ogni
        -- apertura del negozio, e ogni chiamata a pseudoseed/pseudorandom darebbe un numero nuovo
        -- Un tiro per ante, conservato: tornando a un ante già giocato vale lo stesso tiro
        G.GAME.tboi_planetarium_rolls = G.GAME.tboi_planetarium_rolls or {}
        local rolls = G.GAME.tboi_planetarium_rolls
        if not rolls[ante] then
            rolls[ante] = pseudorandom('planetarium_'..ante) * 100
        end
        return rolls[ante] <= G.GAME.planetarium
    end,
    function()
        if TBOI.FUNCS.can_spend('keys', 1) then
            TBOI.FUNCS.ease_keys(-1)
            return true
        end
        attention_text({text = "Not enough keys!", colour = G.C.RED, scale = 0.5, shadow = true})
        return false
    end,
    TBOI.ROOMS.PLANETARIUM
    )
end

-- Create tab buttons
function create_tab_button(tab_name, sprite_pos_x)
    local pos_x = sprite_pos_x or 0
    local scale = 1
    local w = (71 / 34) * scale
    local h = (23 / 34) * scale
    local atlas_key = 'tboi_shop_buttons' 

    local button_sprite = Sprite(0, 0, w, h, G.ASSET_ATLAS[atlas_key], {x = pos_x, y = 0})
    
    button_sprite.update = function(self, dt)
        Sprite.update(self, dt)
        
        local is_active = (TBOI.active_tab == tab_name)
        local is_unlocked = G.GAME.tboi_shop_state and G.GAME.tboi_shop_state.unlocked and G.GAME.tboi_shop_state.unlocked[tab_name]
        
        local target_y = 0
        if is_unlocked then
            target_y = is_active and 1 or 0
        else
            target_y = is_active and 3 or 2
        end
        
        self.sprite_pos.x = pos_x
        self.sprite_pos.y = target_y
    end

    return {n=G.UIT.C, config = {align = 'bm'}, nodes = {
        {n=G.UIT.R, config = {
            align = 'cl', 
            padding = 0.05, 
            hover = true,
            button = 'tboi_toggle_shop_tab', 
            id = 'tboi_tab_'.. tab_name,
            ref_value = tab_name
        }, nodes = {
            {n=G.UIT.O, config = {object = button_sprite}}
        }}
    }}
end

--- Toggles a tab with a new page, removing all others
--- @param e table Event table
function G.FUNCS.tboi_toggle_shop_tab(e)
    local target_tab = e.config.ref_value
    local tab_data = TBOI.custom_shop_tabs[target_tab]

    if not G.GAME.tboi_shop_state.available_tabs[target_tab] then 
        return 
    end

    if not G.GAME.tboi_shop_state.unlocked[target_tab] then
        if  tab_data.unlock_action ~= nil and tab_data.unlock_action() then
            G.GAME.tboi_shop_state.unlocked[target_tab] = true
            play_sound('coin3', 1, 0.6)
            enter_tab(target_tab)
        else
            play_sound('cancel', 1, 0.6)
        end
        return
    end

    if TBOI.active_tab ~= target_tab then
        enter_tab(target_tab)
    end
end

G.FUNCS.tboi_shop_tab_hover = function(e)
    if e.config.ref_value == TBOI.active_tab then
        e.config.colour = G.C.DYN_UI.MAIN
    else
        e.config.colour = G.C.DYN_UI.BOSS_MAIN
    end
end

--- Show Tab, Hide all others
function show_tab(tab_name_to_show)
    local tab_data = TBOI.custom_shop_tabs[tab_name_to_show]
    if not tab_data then return end

    -- NUOVO: scarica (salva + distrugge) la CardArea della pagina che
    -- stiamo lasciando, cosicché non resti in memoria/accessibile mentre
    -- non è sullo schermo (es. G.treasure_room torna a essere nil).
    if TBOI.active_tab and TBOI.active_tab ~= tab_name_to_show then
        TBOI.unload_tab_area(TBOI.active_tab)
    end

    TBOI.active_tab = tab_name_to_show

    -- NUOVO: ricorda quale pagina era aperta dentro G.GAME, cosicché
    -- sopravviva a un salvataggio/ricarica della partita (vedi G.UIDEF.shop
    -- più sotto, che la rilegge all'apertura successiva del negozio).
    G.GAME.tboi_shop_state.active_tab = tab_name_to_show

    local main_shop_body = G.shop:get_UIE_by_ID('tboi_main_shop_body')
    if not main_shop_body then return end


    local function rescue_objects(node)
        if type(node) == 'table' then
            -- Controlliamo che l'oggetto sia specificamente una CardArea prima di salvarlo
            if node.object and type(node.object) == 'table' and node.object.is and node.object:is(CardArea) then
                node.object = nil
            end
            if node.config and node.config.object and type(node.config.object) == 'table' and node.config.object.is and node.config.object:is(CardArea) then
                node.config.object = nil
            end
            if node.children then
                for _, child in ipairs(node.children) do
                    rescue_objects(child)
                end
            end
            
        end
    end
    
    rescue_objects(main_shop_body)

    for i = #main_shop_body.children, 1, -1 do
        main_shop_body.children[i]:remove()
    end
    main_shop_body.children = {}
    
    local new_ui = tab_data.ui_func()
    
    main_shop_body.UIBox:add_child(new_ui, main_shop_body)
    main_shop_body.UIBox:recalculate()

    if tab_data.color then
        if tab_data.color.new_colour then
            ease_background_colour(tab_data.color)
        else
            ease_background_colour({new_colour = tab_data.color, contrast = 2})
        end
    else
        ease_background_colour{new_colour = G.C.BLIND['Small'], contrast = 1}
    end
end

-- Create Tab and switch to it + SetUp
function enter_tab(tab_name)
    local tab = TBOI.custom_shop_tabs[tab_name]

    if not tab or not G.GAME.tboi_shop_state.available_tabs[tab_name] then
        return
    end

    G.GAME.choices = G.GAME.choices or {}
    G.GAME.options = G.GAME.options or {}

    local is_first_time = not G.GAME.tboi_shop_state.visited[tab_name]
    if is_first_time then
        G.GAME.options[tab_name] = G.GAME.total_options or 1
        if tab_name == 'treasure' then
            G.GAME.planetarium = G.GAME.planetarium - 20
        elseif tab_name == 'planetarium' then
            G.GAME.planetarium = 1
            G.GAME.can_planetarium_change = false
        end
    end

    show_tab(tab_name)

    if is_first_time then
        if tab_name == 'treasure' then
            TBOI.FUNCS.gen_item_in_shop({set = 'Joker', area = G.treasure_room, buy_type = 'select'})
        end
        if tab_name == 'planetarium' then
            TBOI.FUNCS.gen_item_in_shop({set = 'Joker', area = G.planetarium, buy_type = 'select'})
        end
        G.GAME.tboi_shop_state.visited[tab_name] = true
    end
end

-- New Standard Shop
function get_vanilla_shop_ui()
    G.E_MANAGER:add_event(Event({
        blocking = false,
        no_delete = true,
        func = function()
            local reroll = G.shop and G.shop:get_UIE_by_ID('shop_reroll')
            if reroll and reroll.UIBox then
                reroll.UIBox:recalculate()
            end
            return true
        end,
    }))

    return {n=G.UIT.C, nodes = {
        {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
            
            {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
                {n=G.UIT.R,config={id = 'next_round_button', align = "cm", minw = 1.8, minh = 1.3, r=0.15, colour = G.C.RED, one_press = true, button = 'toggle_shop', hover = true, shadow = true}, nodes = {
                    {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'y', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                        {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                            {n=G.UIT.T, config={text = localize('b_next_round_1'), scale = 0.4, colour = G.C.WHITE, shadow = true}}
                        }},
                        {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                            {n=G.UIT.T, config={text = localize('b_next_round_2'), scale = 0.4, colour = G.C.WHITE, shadow = true}}
                        }}
                    }},
                }},
                {n=G.UIT.R, config={id = 'shop_reroll', align = "cm", minw = 1.8, minh = 1.3, r=0.15, colour = G.C.GREEN, button = 'reroll_shop', func = 'can_reroll', hover = true, shadow = true}, nodes = {
                    {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'x', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                        {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                            {n=G.UIT.T, config={text = localize('k_reroll'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                        }},
                        {n=G.UIT.R, config={align = "cm", maxw = 1.3, minw = 1}, nodes={
                            {n=G.UIT.T, config={text = localize('$'), scale = 0.7, colour = G.C.WHITE, shadow = true}},
                            {n=G.UIT.T, config={ref_table = G.GAME.current_round, ref_value = 'reroll_cost', scale = 0.75, colour = G.C.WHITE, shadow = true}},
                        }}
                    }}
                }},
            }},
            
            {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.L_BLACK, emboss = 0.05, minw = 8.0}, nodes={
                {n=G.UIT.O, config={object = G.shop_jokers}},
            }},
        }},

        {n=G.UIT.R, config={minh = 0.1}},

        {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
            {n=G.UIT.C, config={align = "cm", padding = 0.15, r=0.2, colour = G.C.L_BLACK, emboss = 0.05}, nodes={
                {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.BLACK, maxh = G.shop_vouchers and (G.shop_vouchers.T.h+0.4) or 1.5}, nodes={
                    {n=G.UIT.T, config={text = localize{type = 'variable', key = 'ante_x_voucher', vars = {G.GAME.round_resets.ante or 1}}, scale = 0.45, colour = G.C.L_BLACK, vert = true}},
                    {n=G.UIT.O, config={object = G.shop_vouchers}},
                }},
            }},
            
            {n=G.UIT.C, config={align = "cm", padding = 0.15, r=0.2, colour = G.C.L_BLACK, emboss = 0.05}, nodes={
                {n=G.UIT.O, config={object = G.shop_booster}},
            }},
        }}
    }}
end

local base_shop_def = G.UIDEF.shop
function G.UIDEF.shop()
    base_shop_def()

    new_shops()

    G.GAME.tboi_shop_state = G.GAME.tboi_shop_state or {}
    G.GAME.tboi_shop_state.visited = G.GAME.tboi_shop_state.visited or {}
    G.GAME.tboi_shop_state.available_tabs = G.GAME.tboi_shop_state.available_tabs or {}
    G.GAME.tboi_shop_state.unlocked = G.GAME.tboi_shop_state.unlocked or {}

    -- FIX 3: Segna il negozio principale come visitato fin da subito
    G.GAME.tboi_shop_state.visited["tboi_main_shop_body"] = true

    for tab_name, tab_data in pairs(TBOI.custom_shop_tabs) do
        if tab_data.can_enter() then
            G.GAME.tboi_shop_state.available_tabs[tab_name] = true
            if not tab_data.unlock_action then
                G.GAME.tboi_shop_state.unlocked[tab_name] = true
            end
        else
            G.GAME.tboi_shop_state.available_tabs[tab_name] = false
        end
    end

    local saved_tab = G.GAME.tboi_shop_state.active_tab
    if saved_tab
        and TBOI.custom_shop_tabs[saved_tab]
        and G.GAME.tboi_shop_state.available_tabs[saved_tab]
        and G.GAME.tboi_shop_state.unlocked[saved_tab]
    then
        TBOI.active_tab = saved_tab
    else
        TBOI.active_tab = "tboi_main_shop_body"
    end
    G.GAME.tboi_shop_state.active_tab = TBOI.active_tab

    local tab_buttons = {}
    for tab_name, tab_data in pairs(TBOI.custom_shop_tabs) do
        if G.GAME.tboi_shop_state.available_tabs[tab_name] then
            table.insert(tab_buttons, create_tab_button(tab_name, tab_data.sprite_pos_x))
            table.insert(tab_buttons, {n=G.UIT.B, config = {w = 0.2, h=0.1}})
        end
    end

    return {n=G.UIT.ROOT, config = {align = 'cl', colour = G.C.CLEAR}, nodes={
        {n=G.UIT.C, config = {align = 'cm'}, nodes = {
            {n=G.UIT.R, config = {align = 'bl', minh = 0.8, colour = G.C.CLEAR, padding = -0.2}, nodes = tab_buttons},
            
            {n=G.UIT.R, config = {align = 'cm', colour = G.C.DYN_UI.MAIN, padding = 0.08, r = 0.1}, nodes = {
                {n=G.UIT.C, config={align = "cm", padding = 0.1, emboss = 0.05, r = 0.1, colour = G.C.DYN_UI.BOSS_MAIN}, nodes={
                    {n=G.UIT.R, config = {id = 'tboi_main_shop_body', align = 'cm'}, nodes = {

                        TBOI.custom_shop_tabs[TBOI.active_tab].ui_func()
                    }}
                }}
            }}
        }}
    }}
end
--- Cambio di ante per le pagine del negozio.
--- Lo stato delle pagine (carte salvate, visitate, sbloccate) di ogni ante viene conservato in
--- G.GAME.tboi_shop_state.ante_pages[ante]: tornando a un ante già giocato (es. andando indietro)
--- le pagine riappaiono com'erano; un ante nuovo parte con pagine vuote.
---@param old_ante number Ante che si sta lasciando
---@param new_ante number Ante in cui si entra
function TBOI.FUNCS.change_shop_ante(old_ante, new_ante)
    local state = G.GAME.tboi_shop_state
    if not state or old_ante == new_ante then return end
    state.visited = state.visited or {}
    state.unlocked = state.unlocked or {}
    state.saved_areas = state.saved_areas or {}
    state.ante_pages = state.ante_pages or {}

    -- La pagina aperta in questo momento va salvata prima di fotografare l'ante,
    -- poi la sua CardArea va tolta SENZA salvarla, altrimenti finirebbe nelle pagine del nuovo ante
    local open_tab = TBOI.active_tab
    local open_global = open_tab and TBOI.tab_area_globals[open_tab]
    if open_global and G[open_global] then
        TBOI.save_tab_area(open_tab)
    end

    state.ante_pages[old_ante] = {
        saved_areas = copy_table(state.saved_areas),
        visited = copy_table(state.visited),
        unlocked = copy_table(state.unlocked),
    }

    local stored = state.ante_pages[new_ante]
    if stored then
        state.saved_areas = copy_table(stored.saved_areas)
        state.visited = copy_table(stored.visited)
        state.unlocked = copy_table(stored.unlocked)
    else
        state.saved_areas = {}
        for k in pairs(state.visited) do state.visited[k] = false end
        for k in pairs(state.unlocked) do state.unlocked[k] = false end
        state.unlocked['treasure'] = new_ante <= 1
    end

    -- Le pagine senza unlock_action (es. il negozio principale) sono sempre aperte
    for k, tab in pairs(TBOI.custom_shop_tabs) do
        if not tab.unlock_action then state.unlocked[k] = true end
    end
    state.visited['tboi_main_shop_body'] = true

    -- Se il negozio è aperto su una pagina con CardArea, si torna al negozio principale:
    -- la pagina verrà ricostruita (con le carte del nuovo ante) alla prossima apertura
    if open_global and G[open_global] then
        G[open_global]:remove()
        G[open_global] = nil
        TBOI.active_tab = 'tboi_main_shop_body'
        state.active_tab = TBOI.active_tab
        if G.shop then show_tab(TBOI.active_tab) end
    end
end
