-- Ordine di creazione dei mazzi della mod: ordine nel selettore e nella collezione.
-- Inserisci le chiavi (senza prefisso, come in `key = ...`) nell'ordine voluto.
-- Il primo è anche il mazzo proposto di default. I mazzi definiti con TBOI.Back{...}
-- ma non elencati qui vengono creati dopo, in ordine di caricamento.
TBOI.DECK_ORDER = {
    'isaac',
    'the_broken',
    'purity',
    'the_dauntless',
    'indulgence',
    'the_hoarder',
    'treachery',
    'the_deceiver',
}

function TBOI.FUNCS.is_deck_allowed(center)
    if not center then return false end
    return not TBOI.VANILLA_DECKS[center.key] or false
end

function TBOI.FUNCS.restrict_decks()
    local pool = G.P_CENTER_POOLS.Back
    for i = #pool, 1, -1 do
        if not TBOI.FUNCS.is_deck_allowed(pool[i]) then
            table.remove(pool, i)
        end
    end

    local profile = G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    local memory = profile and profile.MEMORY
    if memory then
        local remembered = get_deck_from_name(memory.deck)
        -- Ripiego sul primo mazzo rimasto nel pool (il primo di TBOI.DECK_ORDER, se esiste)
        if not TBOI.FUNCS.is_deck_allowed(remembered) and pool[1] then
            memory.deck = pool[1].name
        end
    end
end

-- Il selettore legge pool e mazzo ricordato quando viene costruito: li sistemiamo subito prima
local G_run_setup_option = G.UIDEF.run_setup_option
function G.UIDEF.run_setup_option(type)
    TBOI.FUNCS.restrict_decks()
    return G_run_setup_option(type)
end

--- Codice eseguito all'inizio di ogni run nuova, subito PRIMA della funzione apply del mazzo
--- (vale per tutti i mazzi, anche quelli senza apply). Non viene eseguito continuando una run salvata.
--- In questo momento G.GAME e le regole della puntata sono già pronti, mentre le aree
--- (G.jokers, G.deck, ...) e le carte del mazzo non sono ancora state create.
---@param back table Il mazzo della run (G.GAME.selected_back)
---@param center table Il suo center (back.effect.center): center.key è es. 'b_tboi_isaac'
function TBOI.FUNCS.before_deck_apply(back, center)
    G.GAME.total_options = 0
    G.GAME.joker_max = {}
    G.GAME.bombs = 0
    G.GAME.keys  = 0
    G.GAME.options = {}
    G.GAME.cycle_time = 1
    G.GAME.planetarium = 1
    G.GAME.devil = 0
    G.GAME.angel = 0
    G.GAME.curse = 50
    G.GAME.sacrifice = G.GAME.sacrifice or 33
end

local G_back_apply_to_run = Back.apply_to_run
function Back:apply_to_run(...)
    TBOI.FUNCS.before_deck_apply(self, self.effect.center)
    return G_back_apply_to_run(self, ...)
end

--- Joker iniziali dei mazzi: ogni mazzo può avere nella sua definizione
---     starting_jokers = { 'the_d_six', ... }   (chiavi senza prefisso, come in `key = ...`)
--- Per aggiungere sticker si usa una tabella al posto della chiave:
---     starting_jokers = { { key = 'bag_of_crafting', stickers = { 'eternal' } } }
--- I joker attivi vanno in G.actives, gli altri in G.jokers. Le carte create così hanno
--- card.ability.tboi_starting = true (il mazzo the_hoarder non le distrugge).
--- Le chiavi di joker che non esistono ancora vengono saltate con un avviso nel log.
---@param center table Il center del mazzo
function TBOI.FUNCS.give_starting_jokers(center)
    local keys = center and center.starting_jokers
    if not keys or #keys == 0 then return end

    -- Durante apply_to_run le aree non esistono ancora: le carte si creano con un evento
    G.E_MANAGER:add_event(Event({
        func = function()
            for _, entry in ipairs(keys) do
                local key = type(entry) == 'table' and entry.key or entry
                local stickers = type(entry) == 'table' and entry.stickers or {}
                local full_key = G.P_CENTERS[key] and key or ('j_tboi_'..key)
                local joker = G.P_CENTERS[full_key]
                if not joker then
                    sendWarnMessage(('Joker iniziale "%s" del mazzo %s non esiste'):format(key, center.key), 'TBOI')
                else
                    local area = (joker.config and joker.config.is_active and G.actives) or G.jokers
                    local card = SMODS.create_card{ key = full_key, area = area, skip_materialize = true }
                    -- Il flag va messo prima di add_to_deck, che fa scattare il contesto card_added
                    card.ability.tboi_starting = true
                    for _, sticker in ipairs(stickers) do card:add_sticker(sticker, true) end
                    card:add_to_deck()
                    area:emplace(card)
                end
            end
            return true
        end
    }))
end

--- Slot dei joker attivi: un mazzo può avere `active_slots = n` nella sua definizione (default 1).
--- G.actives non esiste ancora durante apply_to_run: il limite si imposta con un evento.
--- Il limite viene salvato con l'area, quindi resta anche continuando la run.
---@param center table Il center del mazzo
function TBOI.FUNCS.set_active_slots(center)
    local slots = center and center.active_slots
    if not slots then return end
    G.E_MANAGER:add_event(Event({
        func = function()
            if G.actives then G.actives.config.card_limit = slots end
            return true
        end
    }))
end

local G_back_apply_to_run_start = Back.apply_to_run
function Back:apply_to_run(...)
    local ret = G_back_apply_to_run_start(self, ...)
    TBOI.FUNCS.set_active_slots(self.effect.center)
    TBOI.FUNCS.give_starting_jokers(self.effect.center)
    return ret
end

--- Valore di un campo della definizione del mazzo della run (es. deck_flag('no_red_hearts')),
--- nil se non c'è una run o il mazzo non ha quel campo
function TBOI.FUNCS.deck_flag(name)
    local back = G.GAME and G.GAME.selected_back
    local center = back and back.effect and back.effect.center
    return center and center[name]
end

--- true se il mazzo della run permette di prendere joker anche senza spazio
--- (campo `ignore_joker_space = true` nella definizione del mazzo, es. the_hoarder)
function TBOI.FUNCS.ignores_joker_space(card)
    local back = G.GAME and G.GAME.selected_back
    local center = back and back.effect and back.effect.center
    return center and center.ignore_joker_space and card and card.ability.set == 'Joker' or false
end

-- Comprare dal negozio
local G_check_for_buy_space = G.FUNCS.check_for_buy_space
G.FUNCS.check_for_buy_space = function(card)
    if TBOI.FUNCS.ignores_joker_space(card) then return true end
    return G_check_for_buy_space(card)
end

-- Selezionare da una busta
local G_can_select_card = G.FUNCS.can_select_card
G.FUNCS.can_select_card = function(e)
    if TBOI.FUNCS.ignores_joker_space(e.config.ref_table) then
        e.config.colour = G.C.GREEN
        e.config.button = 'use_card'
        return
    end
    return G_can_select_card(e)
end
