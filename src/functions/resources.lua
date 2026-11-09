-- Risorse aggiunte dalla mod (bombe, chiavi, cuori, batterie, carte...).
-- Contatori in G.GAME.bombs / G.GAME.keys, tiro delle ricompense, effetti di ogni risorsa e incasso.
-- Le tabelle costanti (TBOI.RESOURCES, TBOI.RESOURCES_TYPE, TBOI.RESOURCE_CATEGORY_WEIGHTS,
-- TBOI.END_OF_ROUND_REWARDS, TBOI.RESOURCE_ICONS) sono in src/records/resources.lua

-------------------------------------------------------------------------------------------------
-- Contatori (chiavi, bombe)
-------------------------------------------------------------------------------------------------

--- true se il contatore è infinito per l'ante attuale (Golden Key / Golden Bomb)
---@param field string 'keys' o 'bombs'
function TBOI.FUNCS.is_infinite(field)
    local inf = G.GAME.tboi_infinite
    return inf and inf[field] == G.GAME.round_resets.ante or false
end

--- true se si possono spendere `amount` unità del contatore
---@param field string 'keys' o 'bombs'
function TBOI.FUNCS.can_spend(field, amount)
    return TBOI.FUNCS.is_infinite(field) or (G.GAME[field] or 0) >= (amount or 1)
end

--- Modifica un contatore in G.GAME mostrando il popup sul suo elemento della HUD.
--- Se il contatore è infinito per l'ante attuale, spendere non lo diminuisce.
---@param field string Campo di G.GAME ('bombs', 'keys')
---@param ui_id string Id dell'elemento della HUD
---@param amount number Quantità da aggiungere (negativa per togliere)
local function ease_counter(field, ui_id, amount)
    amount = amount or 0
    if amount == 0 then return end
    if amount < 0 and TBOI.FUNCS.is_infinite(field) then return end

    G.GAME[field] = (G.GAME[field] or 0) + amount

    local ui = G.HUD and G.HUD:get_UIE_by_ID(ui_id)
    if ui then
        ui:juice_up()
        attention_text({
            text = (amount > 0 and '+' or '')..tostring(amount),
            colour = amount < 0 and G.C.RED or G.C.WHITE,
            scale = 0.8,
            hold = 0.6,
            cover = ui,
            align = 'cm',
        })
    end
end

---Function to ease the bombs value with a visual
---@param amount number of bombs to give or remove
function TBOI.FUNCS.ease_bombs(amount)
    ease_counter('bombs', 'bomb_UI_count', amount)
end

---Function to ease the keys value with a visual
---@param amount number of keys to give or remove
function TBOI.FUNCS.ease_keys(amount)
    ease_counter('keys', 'key_UI_count', amount)
end

--- Rende infinito un contatore fino alla fine dell'ante attuale
local function set_infinite(field)
    G.GAME.tboi_infinite = G.GAME.tboi_infinite or {}
    G.GAME.tboi_infinite[field] = G.GAME.round_resets.ante
end

-------------------------------------------------------------------------------------------------
-- Effetti delle risorse
-------------------------------------------------------------------------------------------------

--- Primo joker attivo che può ricevere cariche (max_charge > 0), nil se non c'è
local function first_chargeable_active()
    for _, card in ipairs(G.actives and G.actives.cards or {}) do
        if card.ability.is_active and (card.ability.max_charge or 0) > 0 then return card end
    end
end

--- Carica del tutto un joker attivo
local function full_charge(card)
    if card then card:increment_charge(card.ability.max_charge) end
end

--- Danno che non scende sotto mezzo cuore
local function safe_damage(amount)
    local damage = math.min(amount, TBOI.FUNCS.get_total_health() - 1)
    if damage > 0 then TBOI.FUNCS.take_damage(damage) end
end

--- Effetti di ogni risorsa quando arriva al giocatore.
---   dollars: soldi dati (numero o funzione che lo restituisce). Nella valutazione del round
---            vanno nel totale del pulsante Incassa, altrimenti vengono dati subito.
---   effect:  funzione eseguita quando la risorsa viene incassata.
--- Le risorse senza voce (pill, rune, poop...) non fanno nulla: si possono comunque raccogliere
--- con la Bag of Crafting.
TBOI.RESOURCE_EFFECTS = {
    -- Monete
    dollar       = { dollars = 1 },
    double_penny = { dollars = 2 },
    nickel       = { dollars = 5 },
    dime         = { dollars = 10 },
    golden_penny = { dollars = function() return pseudorandom('tboi_golden_penny', 0, 25) end },
    lucky_penny  = { dollars = 1, effect = function()
        -- +1 alla probabilità degli effetti casuali (come Oops! All 6s, ma +1 invece di x2)
        G.GAME.probabilities.normal = G.GAME.probabilities.normal + 1
        G.GAME.tboi_luck = (G.GAME.tboi_luck or 0) + 1
    end },

    -- Chiavi
    key          = { effect = function() TBOI.FUNCS.ease_keys(1) end },
    key_ring     = { effect = function() TBOI.FUNCS.ease_keys(2) end },
    golden_key   = { effect = function() set_infinite('keys') end },
    charged_key  = { effect = function()
        TBOI.FUNCS.ease_keys(1)
        full_charge(first_chargeable_active())
    end },

    -- Bombe
    bomb         = { effect = function() TBOI.FUNCS.ease_bombs(1) end },
    double_bomb  = { effect = function() TBOI.FUNCS.ease_bombs(2) end },
    golden_bomb  = { effect = function() set_infinite('bombs') end },

    -- Cuori
    red_heart        = { effect = function() TBOI.FUNCS.add_red_heart(2) end },
    half_red_heart   = { effect = function() TBOI.FUNCS.add_red_heart(1) end },
    double_red_heart = { effect = function() TBOI.FUNCS.add_red_heart(4) end },
    rotted_heart     = { effect = function() TBOI.FUNCS.add_rotten_heart(1) end },
    soul_heart       = { effect = function() TBOI.FUNCS.add_soul_heart('blue', 2) end },
    half_soul_heart  = { effect = function() TBOI.FUNCS.add_soul_heart('blue', 1) end },
    black_heart      = { effect = function() TBOI.FUNCS.add_soul_heart('black', 2) end },
    half_black_heart = { effect = function() TBOI.FUNCS.add_soul_heart('black', 1) end },
    eternal_heart    = { effect = function() TBOI.UIDEF.add_overlay('eternal') end },
    golden_heart     = { effect = function() TBOI.UIDEF.add_overlay('gold') end },
    bone_heart       = { effect = function() TBOI.FUNCS.add_container('bone', 0) end },

    -- Batterie
    micro_battery  = { effect = function()
        local card = first_chargeable_active()
        if card then card:increment_charge(1) end
    end },
    lil_battery    = { effect = function() full_charge(first_chargeable_active()) end },
    mega_battery   = { effect = function()
        -- Doppio delle cariche massime: supera il limite normale di increment_charge
        local card = first_chargeable_active()
        if card then
            card.ability.charge = card.ability.max_charge * 2
            SMODS.calculate_effect({ message = 'Mega Charge!' }, card)
        end
    end },
    golden_battery = { effect = function()
        for _, card in ipairs(G.actives and G.actives.cards or {}) do
            if card.ability.is_active and (card.ability.max_charge or 0) > 0 then full_charge(card) end
        end
        safe_damage(2) -- 1 cuore, ma si resta ad almeno mezzo cuore
    end },

    -- Carte
    tarot_card   = { effect = function()
        if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            SMODS.add_card{ set = 'Tarot', key_append = 'tboi_tarot_card' }
        end
    end },
    playing_card = { effect = function()
        SMODS.add_card{ set = 'Playing Card', area = G.deck, key_append = 'tboi_playing_card' }
    end },
    special_card = { effect = function()
        -- Solo le carte speciali già create come consumabili (c_tboi_<chiave>)
        local existing = {}
        for _, key in ipairs(TBOI.SPECIAL_CARDS) do
            if G.P_CENTERS['c_tboi_'..key] then table.insert(existing, 'c_tboi_'..key) end
        end
        if #existing > 0 and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            SMODS.add_card{ key = pseudorandom_element(existing, pseudoseed('tboi_special_card')) }
        end
    end },
}

--- Soldi dati da una risorsa (0 se non è una moneta)
function TBOI.FUNCS.resource_dollars(resource)
    local fx = TBOI.RESOURCE_EFFECTS[resource]
    local d = fx and fx.dollars
    if type(d) == 'function' then return d() end
    return d or 0
end

--- Esegue l'effetto (non monetario) di una risorsa
function TBOI.FUNCS.apply_resource_effect(resource)
    local fx = TBOI.RESOURCE_EFFECTS[resource]
    if fx and fx.effect then fx.effect() end
end

--- Dà subito una risorsa al giocatore (fuori dalla valutazione del round)
---@param resource string Tipo di risorsa (vedi TBOI.RESOURCES)
function TBOI.FUNCS.give_resource(resource)
    local dollars = TBOI.FUNCS.resource_dollars(resource)
    if dollars > 0 then ease_dollars(dollars) end
    TBOI.FUNCS.apply_resource_effect(resource)
end

-------------------------------------------------------------------------------------------------
-- Tiro delle risorse
-------------------------------------------------------------------------------------------------

--- Sceglie una voce in una lista di { name, weight } secondo i pesi
local function weighted_pick(entries, seed_key)
    local total = 0
    for _, e in ipairs(entries) do total = total + e.weight end
    if total <= 0 then return nil end
    local roll = pseudorandom(pseudoseed(seed_key)) * total
    local cumulative = 0
    for _, e in ipairs(entries) do
        cumulative = cumulative + e.weight
        if roll <= cumulative then return e.name end
    end
    return entries[#entries].name
end

--- Estrae una risorsa in due fasi: prima la categoria (TBOI.RESOURCE_CATEGORY_WEIGHTS),
--- poi il tipo dentro la categoria (pesi di TBOI.END_OF_ROUND_REWARDS)
---@param seed_key string
---@param skip_nothing boolean? true per non estrarre mai 'nothing'
---@return string resource Tipo estratto ('nothing' se il tiro va a vuoto)
function TBOI.FUNCS.roll_end_of_round_reward(seed_key, skip_nothing)
    -- Ordine fisso delle categorie (pairs non è ordinato e cambierebbe i risultati a parità di seed)
    local categories = {}
    for _, name in ipairs({ 'nothing', 'heart', 'bomb', 'coin', 'key', 'pill', 'card', 'battery' }) do
        local w = TBOI.RESOURCE_CATEGORY_WEIGHTS[name] or 0
        if not (skip_nothing and name == 'nothing') then
            table.insert(categories, { name = name, weight = w })
        end
    end
    local category = weighted_pick(categories, seed_key..'_category')
    if not category or category == 'nothing' then return 'nothing' end

    local weights = {}
    for _, r in ipairs(TBOI.END_OF_ROUND_REWARDS) do weights[r.type] = r.weight end
    local types = {}
    for _, t in ipairs(TBOI.RESOURCES_TYPE[category] or {}) do
        table.insert(types, { name = t, weight = weights[t] or 0 })
    end
    return weighted_pick(types, seed_key..'_type') or 'nothing'
end

-------------------------------------------------------------------------------------------------
-- Ricompense di fine round
-------------------------------------------------------------------------------------------------

---Generates a random ammount of resources at the end of a round
---@param config (table) Table of all needed parameters
function TBOI.FUNCS.grant_random_end_of_round_reward(config)
    config = config or {}
    local amount_per_roll = config.amount or 1
    local rolls = config.rolls or 1

    local seed_key = config.seed_key
        or (config.card and ('eor_reward_'..tostring(config.card.sort_id or config.card.ability.name)))
        or (config.name and ('eor_reward_'..config.name))
        or 'eor_reward'
    seed_key = seed_key..'_'..tostring(G.GAME.round or 0)

    -- Quantità per tipo di risorsa: { key = 2, red_heart = 1, ... }
    local amounts = {}
    local got_something = false

    for i = 1, rolls do
        local reward = TBOI.FUNCS.roll_end_of_round_reward(seed_key..'_roll_'..i)
        if reward ~= 'nothing' then
            -- Solo le ricompense casuali del round (bag_collectable) possono finire nella Bag of Crafting
            if config.bag_collectable and TBOI.FUNCS.bag_collect(reward) then
                -- raccolta dalla borsa: il giocatore non la riceve
            else
                amounts[reward] = (amounts[reward] or 0) + amount_per_roll
                got_something = true
            end
        end
    end

    if got_something then
        TBOI.FUNCS.add_multi_currency_round_eval_row({
            name = config.name or seed_key,
            amounts = amounts,
            bonus = config.bonus,
            card = config.card,
            label = config.label,
            pitch = config.pitch,
            threshold = config.threshold
        })
    end

    return amounts
end

--- Registra le risorse vinte nella valutazione del round:
--- le monete vanno subito nel totale del pulsante Incassa (G.GAME.current_round.dollars, pagato
--- dal gioco), gli altri effetti in G.GAME.pending_round_rewards.items, eseguiti all'incasso.
---@param amounts table { [tipo] = quantità }
function TBOI.FUNCS.register_pending_resources(amounts)
    local pending = G.GAME.pending_round_rewards
    if not pending or pending.round ~= G.GAME.round then
        pending = { round = G.GAME.round, items = {} }
        G.GAME.pending_round_rewards = pending
    end
    pending.items = pending.items or {}

    for resource, count in pairs(amounts) do
        for _ = 1, count do
            local dollars = TBOI.FUNCS.resource_dollars(resource)
            if dollars > 0 then
                G.GAME.current_round.dollars = (G.GAME.current_round.dollars or 0) + dollars
            end
            local fx = TBOI.RESOURCE_EFFECTS[resource]
            if fx and fx.effect then
                pending.items[resource] = (pending.items[resource] or 0) + 1
            end
        end
    end
end

-- All'incasso esegue gli effetti delle risorse accumulate durante la valutazione del round.
-- I soldi no: sono già nel totale del round, che il gioco paga da solo.
local cash_out = G.FUNCS.cash_out
G.FUNCS.cash_out = function(e)
    local pending = G.GAME and G.GAME.pending_round_rewards
    if pending and pending.items then
        for _, r in ipairs(TBOI.RESOURCES) do
            for _ = 1, pending.items[r.key] or 0 do
                TBOI.FUNCS.apply_resource_effect(r.key)
            end
        end
    end
    G.GAME.pending_round_rewards = { round = G.GAME.round, items = {} }

    if cash_out then cash_out(e) end
end

-- Ricompensa casuale assegnata a ogni valutazione del round
SMODS.current_mod.calculate = function(self, context)
    if context.round_eval then
        TBOI.FUNCS.grant_random_end_of_round_reward({
            name = 'mod_reward_'..tostring(G.GAME.round or 0),
            bonus = true,
            pitch = 1,
            rolls = math.max(math.floor((G.GAME.round_resets.ante - 1) / 2), 0) + 1,
            amount = 1,
            label = 'Ricompensa casuale del round',
            bag_collectable = true, -- la Bag of Crafting raccoglie queste ricompense
        })
    end
end

--- Mazzo the_hoarder: risorse date quando un joker ottenuto viene distrutto.
--- Ogni risorsa va nella Bag of Crafting se ce n'è una non piena, altrimenti al giocatore.
---@param card table Il joker distrutto
function TBOI.FUNCS.hoarder_reward(card)
    local cfg = TBOI.HOARDER_REWARDS
    local amount = pseudorandom('tboi_hoarder_amount', cfg.min, cfg.max)
    for i = 1, amount do
        local resource = TBOI.FUNCS.roll_end_of_round_reward('tboi_hoarder_'..i, true)
        if not TBOI.FUNCS.bag_collect(resource) then
            TBOI.FUNCS.give_resource(resource)
        end
    end
end
