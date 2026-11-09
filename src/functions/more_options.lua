-- Il ciclo di una carta è salvato in card.ability.tboi_cycle = { keys = {...}, time = n }.
-- card.ability viene serializzata da Card:save, quindi il ciclo sopravvive al salvataggio
-- della partita senza bisogno di altri dati in G.GAME.

---@param self table The starting card the function is called with.
---@param keys table Table of all center keys the card cycles between (the first is the original one).
---@param time number? Durata in secondi di un giro completo del ciclo (tutte le carte), default 1.
function Card:set_cycle(keys, time)
    local cycle_table = {}
    local valid_keys = {}
    for _, key in ipairs(keys) do
        if G.P_CENTERS[key] then
            table.insert(cycle_table, G.P_CENTERS[key])
            table.insert(valid_keys, key)
        end
    end

    self.cycle_index = nil
    self.cycle_time = time or 1
    self.cycle_table = cycle_table
    self.ability.tboi_cycle = { keys = valid_keys, time = self.cycle_time }
end

---@param self table The starting card the function is called with.
---@param amount int number of cards to cycle between.
---@param time number? Durata in secondi di un giro completo del ciclo (tutte le carte), default 1.
function Card:init_cycle(amount, time)
    if self.cycle_table then return end

    local keys = { self.config.center.key } -- il joker che la carta aveva all'origine
    -- Le chiavi già scelte per questo ciclo sono escluse dalle estrazioni successive (vedi get_current_pool)
    TBOI.pending_cycle_keys = { [self.config.center.key] = true }
    for _ = 1, (amount or 1) do
        local ok, next_card = pcall(function()
            return SMODS.poll_object{ type = 'Joker' }
        end)
        local key = ok and next_card and (type(next_card) == 'table' and next_card.key or next_card)
        if not key then
            sendWarnMessage('poll_object fallito in init_cycle: '..tostring(next_card), 'TBOI')
            break
        end
        -- Pool esaurito: SMODS ripiega su un joker di default già presente, ci fermiamo
        if TBOI.pending_cycle_keys[key] then break end
        TBOI.pending_cycle_keys[key] = true
        table.insert(keys, key)
    end
    TBOI.pending_cycle_keys = nil
    self:set_cycle(keys, time)
end

--- Tutti i joker "prenotati" dai cicli delle carte nelle aree del negozio
--- (e delle pagine salvate ma non caricate), così da non poter essere generati di nuovo.
--- È calcolato al momento: quando una carta viene comprata o rimossa, i suoi joker tornano disponibili.
function TBOI.FUNCS.get_reserved_cycle_keys()
    local reserved = {}
    local function add_cycle(cycle)
        if cycle and cycle.keys then
            for _, k in ipairs(cycle.keys) do reserved[k] = true end
        end
    end

    for _, area in pairs({ G.shop_jokers, G.pack_cards, G.planetarium, G.treasure_room }) do
        if area and area.cards then
            for _, card in ipairs(area.cards) do
                if card.config and card.config.center then reserved[card.config.center.key] = true end
                add_cycle(card.ability and card.ability.tboi_cycle)
            end
        end
    end

    -- Pagine del negozio salvate ma al momento non caricate (solo finché si è nel negozio)
    local saved = G.shop and G.GAME.tboi_shop_state and G.GAME.tboi_shop_state.saved_areas
    if saved then
        for tab_name, cards in pairs(saved) do
            local global_name = TBOI.tab_area_globals[tab_name]
            if not (global_name and G[global_name]) then
                for _, card_data in ipairs(cards) do
                    if card_data.key then reserved[card_data.key] = true end
                    add_cycle(card_data.cycle)
                end
            end
        end
    end

    for k in pairs(TBOI.pending_cycle_keys or {}) do reserved[k] = true end
    return reserved
end

-- Durante la creazione del pool dei Joker, i joker prenotati vengono trattati come "già usati":
-- get_current_pool li esclude come fa con quelli posseduti (Showman compreso) e mantiene
-- il suo ripiego automatico se il pool resta vuoto.
local G_get_current_pool = get_current_pool
function get_current_pool(_type, ...)
    if _type ~= 'Joker' or not (G.GAME and G.GAME.used_jokers) then
        return G_get_current_pool(_type, ...)
    end

    local added = {}
    for key in pairs(TBOI.FUNCS.get_reserved_cycle_keys()) do
        if not G.GAME.used_jokers[key] then
            G.GAME.used_jokers[key] = true
            added[#added + 1] = key
        end
    end

    local rets = { pcall(G_get_current_pool, _type, ...) }

    for _, key in ipairs(added) do
        G.GAME.used_jokers[key] = nil
    end
    if not rets[1] then error(rets[2], 0) end
    return unpack(rets, 2)
end

--- Ripristina il ciclo salvato in ability (dopo Card:load o dopo il restore di una pagina del negozio)
---@param saved table? { keys = {...}, time = n }
function Card:restore_cycle(saved)
    saved = saved or (self.ability and self.ability.tboi_cycle)
    if not saved or not saved.keys or #saved.keys == 0 then return false end
    self:set_cycle(saved.keys, saved.time)
    return true
end

---@param self table The starting card the function is called with.
---@param area table The area the card is in
function Card:cycle_card(timer, area)
    local cycle_table = self.cycle_table
    if not cycle_table or #cycle_table == 0 then return end

    -- cycle_time è la durata dell'intero giro: ogni carta resta cycle_time / #cycle_table secondi,
    -- quindi in un giro (1 secondo di default) si vedono tutte le carte, quante che siano
    local idx = math.floor(timer * #cycle_table / self.cycle_time) % #cycle_table + 1
    if idx == self.cycle_index then return end

    self.cycle_index = idx
    local new_center = cycle_table[idx]
    if not new_center or new_center == self.config.center then return end

    -- SMODS.clean_up_children (chiamata da set_ability) distrugge tutti i figli della carta,
    -- compresi prezzo e pulsanti: li stacchiamo prima e li riattacchiamo dopo.
    -- I pulsanti hanno ref_table = self, quindi restano validi anche col nuovo center.
    local kept = {}
    for _, k in ipairs(TBOI.CYCLE_KEPT_CHILDREN) do
        kept[k] = self.children[k]
        self.children[k] = nil
    end
    -- (ability.tboi_cycle sopravvive da solo: SMODS set_ability unisce la nuova ability alla vecchia)
    -- set_ability copia original_T (la posizione in cui la carta è stata creata) in self.T e solo
    -- dopo ricrea alcuni figli (es. floating_sprite) in quel punto: la carta e i figli volerebbero
    -- da lì al loro posto, visibili anche se l'area è fuori schermo.
    -- Durante la chiamata original_T punta quindi alla posizione attuale; w/h restano quelli
    -- base, perché set_ability li usa per ricalcolare le dimensioni dei joker speciali.
    local original_T = self.original_T
    self.original_T = {
        x = self.T.x, y = self.T.y, r = self.T.r,
        w = original_T.w, h = original_T.h, scale = original_T.scale,
    }

    -- delay_sprites = false: la pulizia dei figli avviene subito, non in un evento successivo
    self:set_ability(new_center, false, false)

    self.original_T = original_T

    for k, v in pairs(kept) do
        self.children[k] = v
    end
    self:set_cost()
end


function TBOI.FUNCS.cycle_options(area)
    if area == nil or area.cards == nil then return end
    -- Mentre una busta è aperta le altre aree sono fuori schermo: non cambiamo le loro carte.
    -- Chiusa la busta G.pack_cards resta assegnata ma con REMOVED (stesso controllo del gioco)
    local pack_open = G.pack_cards and not G.pack_cards.REMOVED
    if pack_open and area ~= G.pack_cards then return end
    for _,card in pairs(area.cards) do
        if card then
            -- Unico punto di inizializzazione dei cicli: vale sia per le carte nuove sia per
            -- quelle ricaricate da un salvataggio (il ciclo salvato sta in ability.tboi_cycle)
            if not card.cycle_table and card.ability and card.ability.set == 'Joker' then
                if not card:restore_cycle() then
                    card:init_cycle(G.GAME.total_options, G.GAME.cycle_time)
                end
            end
            -- G.TIMERS.REAL: tempo reale. G.TIMERS.TOTAL scorre più veloce con la velocità di gioco
            -- (impostazione Game Speed, es. x4), e il ciclo durerebbe meno di cycle_time secondi
            card:cycle_card(G.TIMERS.REAL, area)
        end
    end
end
