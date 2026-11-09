function TBOI.FUNCS.update_cash_out_ui()
    if not G.round_eval then return end
    
    local button = G.round_eval:get_UIE_by_ID('cash_out_button')
    if not button then return end

    -- Rimuove eventuali vecchi badge dal pulsante
    local old_extra = G.round_eval:get_UIE_by_ID('tboi_cash_out_extra')
    if old_extra then old_extra:remove() end

    local pending = G.GAME.pending_round_rewards or {}
    local items = pending.items or {}
    local extra_nodes = {}

    -- Aggiunge il conteggio delle risorse pendenti (non monetarie) sotto il pulsante
    for _, curr_name in ipairs(TBOI.FUNCS.resource_order(items)) do
        local amount = items[curr_name] or 0
        if amount > 0 then
            local currency = TBOI.FUNCS.resource_display(curr_name)
            table.insert(extra_nodes, {
                n = G.UIT.O,
                config = {
                    object = DynaText({
                        string = { '+' .. amount .. currency.icon },
                        colours = { currency.colour },
                        font = currency.font,
                        shadow = true,
                        scale = 0.5
                    })
                }
            })
        end
    end

    if #extra_nodes > 0 then
        local extra_ui = {
            n = G.UIT.R,
            config = { align = "cm", id = 'tboi_cash_out_extra', padding = 0.05 },
            nodes = extra_nodes
        }
        G.round_eval:add_child(extra_ui, button)
    end
end




function TBOI.FUNCS.add_multi_currency_round_eval_row(config)
    config = config or {}
    assert(config.amounts, "add_multi_currency_round_eval_row: config.amounts è obbligatorio")
    assert(config.name, "add_multi_currency_round_eval_row: config.name è obbligatorio")

    local width = G.round_eval.T.w - 0.51
    local threshold = config.threshold or 60
    local scale = 0.9
    local container_id = config.bonus and 'bonus_round_eval' or 'base_round_eval'
    local currency_order = TBOI.FUNCS.resource_order(config.amounts)

    -- Monete nel totale del round, altri effetti in attesa dell'incasso
    TBOI.FUNCS.register_pending_resources(config.amounts)

    -- Linea tratteggiata
    if not G.round_eval.divider_added then
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.25,
            func = function()
                local spacer = {n=G.UIT.R, config={align = "cm", minw = width}, nodes={
                    {n=G.UIT.O, config={object = DynaText({string = {'......................................'}, colours = {G.C.WHITE}, shadow = true, float = true, y_offset = -30, scale = 0.45, spacing = 13.5, font = G.LANGUAGES['en-us'].font, pop_in = 0})}}
                }}
                G.round_eval:add_child(spacer, G.round_eval:get_UIE_by_ID(container_id))
                return true
            end
        }))
        delay(0.6)
        G.round_eval.divider_added = true
    end

    delay(0.2)

    G.E_MANAGER:add_event(Event({
        trigger = 'before', delay = 0.5,
        func = function()
            local left_text = {}
            if config.card then
                table.insert(left_text, {n=G.UIT.O, config={object = DynaText({
                    string = localize{type = 'name_text', set = config.card.config.center.set, key = config.card.config.center.key},
                    colours = {G.C.FILTER}, shadow = true, pop_in = 0, scale = 0.6*scale, silent = true
                })}})
            elseif config.label then
                table.insert(left_text, {n=G.UIT.O, config={object = DynaText({
                    string = {config.label}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true
                })}})
            end

            local right_nodes = {}
            for _, curr_name in ipairs(currency_order) do
                local amt = config.amounts[curr_name]
                if amt and amt > 0 then
                    table.insert(right_nodes, {
                        n=G.UIT.C, config={align = "cm", id = 'currency_'..curr_name..'_'..config.name, padding = 0.2}, nodes={}
                    })
                end
            end

            local full_row = {n=G.UIT.R, config={align = "cm", minw = 5}, nodes={
                {n=G.UIT.C, config={padding = 0.05, minw = width*0.55, minh = 0.61, align = "cl"}, nodes = left_text},
                {n=G.UIT.C, config={padding = 0.05, minw = width*0.45, align = "cr"}, nodes={
                    {n=G.UIT.R, config={align = "cr"}, nodes=right_nodes} 
                }}
            }}

            G.round_eval:add_child(full_row, G.round_eval:get_UIE_by_ID(container_id))
            play_sound('cancel', config.pitch or 1)
            play_sound('highlight1', 1.5*(config.pitch or 1), 0.2)
            if config.card then config.card:juice_up(0.7, 0.46) end

            -- Aggiorna la grafica del pulsante Incassa in tempo reale
            TBOI.FUNCS.update_cash_out_ui()

            return true
        end
    }))

    -- Animazioni visive delle icone nella riga
    for _, curr_name in ipairs(currency_order) do
        local amount = config.amounts[curr_name]
        if amount and amount > 0 then
            local currency = TBOI.FUNCS.resource_display(curr_name)
            local icon_row = 0
            local c_font = currency.font

            if amount > threshold then
                G.E_MANAGER:add_event(Event({
                    trigger = 'before', delay = 0.38,
                    func = function()
                        G.round_eval:add_child(
                            {n=G.UIT.R, config={align = "cm", id = 'currency_row_'..(icon_row+1)..'_'..curr_name..'_'..config.name}, nodes={
                                {n=G.UIT.O, config={object = DynaText({
                                    string = {currency.icon..amount},
                                    colours = {currency.colour},
                                    font = c_font, -- Font assegnato in modo sicuro
                                    shadow = true, pop_in = 0, scale = 0.65, float = true
                                })}}
                            }},
                            G.round_eval:get_UIE_by_ID('currency_'..curr_name..'_'..config.name))
                        play_sound('coin3', 0.9+0.2*math.random(), 0.7)
                        play_sound('coin6', 1.3, 0.8)
                        return true
                    end
                }))
            else
                for i = 1, amount do
                    G.E_MANAGER:add_event(Event({
                        trigger = 'before', delay = 0.18 - ((amount > 20 and 0.13) or (amount > 9 and 0.1) or 0),
                        func = function()
                            if i % 30 == 1 then
                                G.round_eval:add_child(
                                    {n=G.UIT.R, config={align = "cm", id = 'currency_row_'..(icon_row+1)..'_'..curr_name..'_'..config.name}, nodes={}},
                                    G.round_eval:get_UIE_by_ID('currency_'..curr_name..'_'..config.name))
                                icon_row = icon_row + 1
                            end

                            local r = {n=G.UIT.T, config={
                                text = currency.icon,
                                colour = currency.colour,
                                font = c_font, -- Font assegnato in modo sicuro
                                scale = ((amount > 20 and 0.28) or (amount > 9 and 0.43) or 0.58),
                                shadow = true, hover = true, can_collide = false, juice = true
                            }}
                            play_sound('coin3', 0.9+0.2*math.random(), 0.7 - (amount > 20 and 0.2 or 0))

                            G.round_eval:add_child(r, G.round_eval:get_UIE_by_ID('currency_row_'..(icon_row)..'_'..curr_name..'_'..config.name))
                            G.VIBRATION = G.VIBRATION + 0.4
                            return true
                        end
                    }))
                end
            end
        end
    end
end


--- Tipi presenti in `amounts`, nell'ordine di TBOI.RESOURCES (poi quelli non elencati)
---@param amounts table { [tipo] = quantità }
function TBOI.FUNCS.resource_order(amounts)
    local order, seen = {}, {}
    for _, r in ipairs(TBOI.RESOURCES) do
        if (amounts[r.key] or 0) > 0 then table.insert(order, r.key); seen[r.key] = true end
    end
    for key, amount in pairs(amounts) do
        if not seen[key] and amount > 0 then table.insert(order, key) end
    end
    return order
end

--- Icona, colore e font di una risorsa (TBOI.RESOURCE_ICONS), con un ripiego se manca
function TBOI.FUNCS.resource_display(resource)
    local def = TBOI.RESOURCE_ICONS[resource] or { icon = '?', colour = G.C.WHITE, font = 'm6x11plus' }
    local font = G.LANGUAGES['en-us'].font -- font di Balatro
    if def.font ~= 'm6x11plus' and SMODS.Fonts and SMODS.Fonts[def.font] then
        font = SMODS.Fonts[def.font]
    end
    return { icon = def.icon, colour = def.colour, font = font }
end
