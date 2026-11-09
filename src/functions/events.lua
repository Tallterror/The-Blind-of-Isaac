TBOI.JokersIDPool = {}
TBOI.JokersKeyPool = {}

--- ID dei joker per lo Spindown Dice, nell'ordine di creazione (vanilla, poi quelli delle mod
--- nell'ordine di TBOI.JOKER_ORDER). Va chiamata dopo che SMODS ha iniettato i joker (es. a inizio run):
--- G.P_CENTER_POOLS.Joker è ordinato, mentre pairs(G.P_CENTERS) non lo è.
function TBOI.FUNCS.set_up_pools()
    TBOI.JokersKeyPool = {}
    TBOI.JokersIDPool = {}
    for id, center in ipairs(G.P_CENTER_POOLS.Joker) do
        TBOI.JokersIDPool[id] = center.key
        TBOI.JokersKeyPool[center.key] = id
    end
end

---@param card all cards to remove for the change
---@param new_card table new joker to generate
function TBOI.FUNCS.change_shop_joker(card, new_card, area)
    if area == nil then
        area = card.area or G.shop_jokers
    end
    -- La distruzione avviene con un evento (animazione): finché non finisce la carta vecchia
    -- resta in area.cards e verrebbe salvata al posto della nuova uscendo dalla pagina.
    -- La togliamo subito dall'area, ricordando la posizione per mettere lì la nuova.
    local pos
    for i, c in ipairs(area.cards or {}) do if c == card then pos = i break end end
    if card.area then card.area:remove_card(card) end
    SMODS.destroy_cards(card, true, true)
    local shop_card = nil
    if new_card then
        shop_card = SMODS.create_card{key = new_card, skip_materialize = true, area = area}
    else
        shop_card = SMODS.create_card{set = 'Joker', skip_materialize = true, area = area}
    end
    area:emplace(shop_card)
    -- Rimette la carta nella posizione di quella sostituita
    if pos and pos < #area.cards and area.cards[#area.cards] == shop_card then
        table.remove(area.cards, #area.cards)
        table.insert(area.cards, pos, shop_card)
        area:set_ranks()
    end
    if area == G.shop_jokers then
	    create_shop_card_ui(shop_card, 'Joker', area)
    elseif area ~= G.pack_cards then
        -- Treasure room, planetarium...: pulsante di selezione come le carte create da gen_item_in_shop
        G.UIDEF.create_select_card_ui(shop_card, shop_card.ability.set, area)
    end
    shop_card:juice_up()
end

--@param card Card to check for spindown 'key' counterpart
function TBOI.FUNCS.spindown_result(card)
    if not (card and card.config and card.config.center and card.config.center.key) then return nil end
    local id = TBOI.JokersKeyPool[card.config.center.key] or nil
    if id ~= nil and id > 1 then
        return TBOI.JokersIDPool[id-1]
    end
    return nil
end

---@param args table Table of all needed parameters
function TBOI.FUNCS.gen_item_in_shop(args)
    local _card = args.card
    local _set = args.set
    local _key = args.key
    local _area = args.area
    local buy_type = args.buy_type
    local new_card = nil
    if _card then
        new_card = _card
        _area:emplace(new_card)
    else
        -- create_card + emplace, non add_card: add_card chiama add_to_deck, che farebbe
        -- contare la carta come posseduta (contesto card_added: es. il mazzo the_hoarder la distruggerebbe)
        new_card = SMODS.create_card{
            set = _set,
            key = _key,
            area = _area,
            skip_materialize = true,
            key_append = 'shop_generation'
        }
        _area:emplace(new_card)
    end

    if new_card then
        if buy_type == 'select' then
            G.UIDEF.create_select_card_ui(new_card, new_card.ability.set, _area)
        else
            create_shop_card_ui(new_card, _set or new_card.ability.set, _area)
        end
    end
    return new_card
end

--- Select item interaction
--- @param e table event table, containing many event elements
function G.FUNCS.tboi_select_card(e)
    local card = e.config.ref_table
    if not card or not card.area then return end
    
    local area = card.area

    e.config.button = nil
    if card.children.buy_button then card.children.buy_button:remove(); card.children.buy_button = nil end
    if card.children.use_button then card.children.use_button:remove(); card.children.use_button = nil end
    if card.children.sell_button then card.children.sell_button:remove(); card.children.sell_button = nil end
    if card.children.select_button then card.children.select_button:remove(); card.children.select_button = nil end
    if card.children.price then card.children.price:remove(); card.children.price = nil end

    -- 2. Rimuove la carta dall'area corrente e la aggiunge a G.jokers
    area:remove_card(card)
    local target = TBOI.FUNCS.select_target_area(card)
    if target then
        card:add_to_deck()
        target:emplace(card)
        play_sound('card1', 0.8, 0.6)
        play_sound('generic1')
    end
end

--- Area in cui va una carta selezionata (attivi o joker), nil se non selezionabile
function TBOI.FUNCS.select_target_area(card)
    if card.ability.is_active then return G.actives end
    if card.ability.set == 'Joker' then return G.jokers end
    return nil
end

---Used to interact from the select button
function G.FUNCS.tboi_can_select_card(e)
    local card = e.config.ref_table
    if not card then return end
    local target = TBOI.FUNCS.select_target_area(card)
    if not target then return end
    if #target.cards < target.config.card_limit + (G.GAME.joker_buffer or 0)
    or TBOI.FUNCS.ignores_joker_space(card) then
        e.config.colour = G.C.GREEN
        e.config.button = 'tboi_select_card'
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

--- Excecutes any passed function for each passed area
---@param func function Function to excecute
---@param areas table All areas to check
---@return table area_returns return table of all previous excecutions (doesn't contain any nil returned values)
function TBOI.FUNCS.operate_all_areas(func, areas)
    local area_returns = {}
    -- table.maxn invece di #: la lista può avere buchi (es. G.pack_cards = nil) e # si fermerebbe prima
    for i = 1, table.maxn(areas) do
        if type(areas[i]) == "table" and areas[i].is and areas[i]:is(CardArea) then
            local values = func(areas[i])
            if values then
                table.insert(area_returns, values)
            end
        end
    end
    return area_returns
end