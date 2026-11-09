-- Bag of Crafting: raccolta delle risorse e creazione dei joker.
-- Il contenuto della borsa è salvato in card.ability.extra.contents = { 'key', 'bomb', ... }
-- (tipi di TBOI.END_OF_ROUND_REWARDS), quindi sopravvive a salvataggio e ricarica.
-- Costanti in src/records/resources.lua (TBOI.BAG_OF_CRAFTING).

local function bag_contents(bag)
    if type(bag.ability.extra) ~= 'table' then bag.ability.extra = {} end
    bag.ability.extra.contents = bag.ability.extra.contents or {}
    return bag.ability.extra.contents
end

--- Prima Bag of Crafting posseduta e aperta, nil se non ce n'è.
--- Anche piena può ricevere risorse: bag_collect crea prima il joker con quelle che contiene.
function TBOI.FUNCS.find_open_bag()
    for _, area in ipairs({ G.actives, G.jokers }) do
        if area and area.cards then
            for _, card in ipairs(area.cards) do
                if card.config.center.key == TBOI.BAG_OF_CRAFTING.KEY and not card.debuff
                and not (type(card.ability.extra) == 'table' and card.ability.extra.closed) then
                    return card
                end
            end
        end
    end
end

local function resource_name(resource)
    for _, r in ipairs(TBOI.RESOURCES) do
        if r.key == resource then return r.name end
    end
    return resource
end

--- Mette una risorsa nella Bag of Crafting, se ce n'è una aperta.
--- Quando la borsa arriva a CAPACITY crea un joker (in un evento). Se arriva un'altra risorsa
--- prima di quell'evento, il joker viene creato subito con le risorse precedenti e la nuova
--- entra nella borsa svuotata, così nessuna risorsa in eccesso va persa.
---@param resource string Tipo di risorsa ('dollar', 'key', 'bomb', ...)
---@return boolean collected true se la risorsa è finita nella borsa (il giocatore non la riceve)
function TBOI.FUNCS.bag_collect(resource)
    if not resource or resource == 'nothing' then return false end
    if not TBOI.FUNCS.find_open_bag() then return false end

    -- Alcune risorse entrano nella borsa come altre (es. Double Bomb = 2 Bomb, Half Red Heart = Red Heart):
    -- vedi TBOI.BAG_OF_CRAFTING.CONVERSIONS. Ogni materiale occupa un posto.
    local materials = TBOI.BAG_OF_CRAFTING.CONVERSIONS[resource] or { resource }
    for _, material in ipairs(materials) do
        local bag = TBOI.FUNCS.find_open_bag()
        if bag then
            -- Borsa già piena: prima si crea il joker con le risorse che contiene
            if #bag_contents(bag) >= TBOI.BAG_OF_CRAFTING.CAPACITY then
                TBOI.FUNCS.craft_from_bag(bag)
            end
            -- craft_from_bag sostituisce la tabella del contenuto: va riletta dopo
            local contents = bag_contents(bag)
            table.insert(contents, material)
            card_eval_status_text(bag, 'extra', nil, nil, nil, {
                message = resource_name(material)..' '..#contents..'/'..TBOI.BAG_OF_CRAFTING.CAPACITY,
                colour = G.C.FILTER,
            })
            if #contents >= TBOI.BAG_OF_CRAFTING.CAPACITY then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        TBOI.FUNCS.craft_from_bag(bag)
                        return true
                    end
                }))
            end
        else
            -- La borsa si è riempita a metà risorsa: il resto va al giocatore
            TBOI.FUNCS.give_resource(material)
        end
    end
    return true
end

--- Valore di una risorsa (campo value di TBOI.END_OF_ROUND_REWARDS)
local function resource_value(resource)
    for _, r in ipairs(TBOI.END_OF_ROUND_REWARDS) do
        if r.type == resource then return r.value or 0 end
    end
    return 0
end

--- Ricetta fissa che corrisponde esattamente al contenuto, nil se nessuna (o se il joker non esiste)
local function find_fixed_recipe(contents)
    local counts = {}
    for _, r in ipairs(contents) do counts[r] = (counts[r] or 0) + 1 end

    for _, recipe in ipairs(TBOI.BAG_OF_CRAFTING.FIXED_RECIPES) do
        local needed, matches = 0, true
        for _, m in ipairs(recipe.materials) do
            needed = needed + m.amount
            if counts[m.pickup] ~= m.amount then matches = false break end
        end
        local key = 'j_tboi_'..recipe.item
        if matches and needed == #contents and G.P_CENTERS[key] then
            return key
        end
    end
end

--- Joker casuale la cui rarità dipende dal valore totale delle risorse nella borsa:
---   1. somma dei `value` (TBOI.END_OF_ROUND_REWARDS) -> fascia di TBOI.BAG_OF_CRAFTING.CRAFTING_QUALITY
---   2. qualità casuale tra min_quality e max_quality della fascia
---   3. qualità -> rarità del joker (TBOI.BAG_OF_CRAFTING.QUALITY_TO_RARITY)
--- Se non c'è un joker generabile di quella rarità prova le altre qualità della fascia,
--- e infine sceglie tra tutti i joker generabili.
local function pick_by_quality(contents)
    local total = 0
    for _, r in ipairs(contents) do total = total + resource_value(r) end

    local tier
    for _, t in ipairs(TBOI.BAG_OF_CRAFTING.CRAFTING_QUALITY) do
        if total >= t.min_amount and total <= t.max_amount then tier = t break end
    end

    -- Joker generabili raggruppati per rarità
    local by_rarity, any = {}, {}
    for _, center in ipairs(G.P_CENTER_POOLS.Joker) do
        local allowed = center.key ~= TBOI.BAG_OF_CRAFTING.KEY
            and not (G.GAME.used_jokers[center.key] and not SMODS.showman(center.key))
            and (not center.in_pool or center:in_pool({ source = 'tboi_crafting' }))
        if allowed then
            table.insert(any, center)
            local r = center.rarity
            by_rarity[r] = by_rarity[r] or {}
            table.insert(by_rarity[r], center)
        end
    end

    local pool
    if tier then
        local map = TBOI.BAG_OF_CRAFTING.QUALITY_TO_RARITY
        local quality = pseudorandom('tboi_crafting_quality', tier.min_quality, tier.max_quality)
        pool = by_rarity[map[quality]]
        -- Nessun joker di quella rarità: le altre qualità della fascia, dalla più alta
        if not pool or #pool == 0 then
            for q = tier.max_quality, tier.min_quality, -1 do
                local candidates = by_rarity[map[q]]
                if candidates and #candidates > 0 then pool = candidates break end
            end
        end
    end
    if not pool or #pool == 0 then pool = any end

    local center = pseudorandom_element(pool, pseudoseed('tboi_crafting'))
    return center and center.key
end

--- Svuota la borsa e crea il joker corrispondente, con lo sticker Crafted.
--- I joker attivi vanno in G.actives, gli altri in G.jokers.
function TBOI.FUNCS.craft_from_bag(bag)
    if not bag or bag.removed then return end
    local contents = bag_contents(bag)
    if #contents < TBOI.BAG_OF_CRAFTING.CAPACITY then return end

    local key = find_fixed_recipe(contents) or pick_by_quality(contents)
    bag.ability.extra.contents = {}
    if not key then return end

    local center = G.P_CENTERS[key]
    local area = (center.config and center.config.is_active and G.actives) or G.jokers
    SMODS.add_card{ key = key, area = area, stickers = { 'tboi_crafted' }, force_stickers = true }
    bag:juice_up()
    play_sound('tarot1')
end

--- Righe "xN Risorsa" del contenuto della borsa, nell'ordine di TBOI.RESOURCES
---@return table lines { {amount = n, name = 'Bomb'}, ... }
function TBOI.FUNCS.bag_content_lines(bag)
    local counts = {}
    for _, r in ipairs(bag_contents(bag)) do counts[r] = (counts[r] or 0) + 1 end

    local lines = {}
    for _, r in ipairs(TBOI.RESOURCES) do
        if counts[r.key] then
            table.insert(lines, { amount = counts[r.key], name = r.name })
            counts[r.key] = nil
        end
    end
    -- Risorse non elencate in TBOI.RESOURCES, per non perderle dalla vista
    for key, amount in pairs(counts) do
        table.insert(lines, { amount = amount, name = key })
    end
    return lines
end

-- Riquadro "Resources" accanto alla descrizione della Bag of Crafting (come quello dello Spindown Dice).
-- Si vede solo su una borsa vera (non nella collezione, dove non c'è una carta con un contenuto).
local G_generate_card_ui_bag = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end, card)
    local ui_table = G_generate_card_ui_bag(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end, card)

    if not full_UI_table and type(_c) == 'table' and _c.key == TBOI.BAG_OF_CRAFTING.KEY
    and card and card.ability and type(ui_table) == 'table' and ui_table.info then
        local box = { name = 'Resources' }
        local lines = TBOI.FUNCS.bag_content_lines(card)
        if #lines == 0 then
            table.insert(box, {
                { n = G.UIT.T, config = { text = 'Empty', scale = 0.32, colour = G.C.UI.TEXT_INACTIVE } },
            })
        end
        for _, line in ipairs(lines) do
            table.insert(box, {
                { n = G.UIT.T, config = { text = 'x'..line.amount..' ', scale = 0.32, colour = G.C.FILTER } },
                { n = G.UIT.T, config = { text = line.name, scale = 0.32, colour = G.C.UI.TEXT_DARK } },
            })
        end
        table.insert(ui_table.info, box)
    end
    return ui_table
end

--- Apre o chiude la borsa. Chiusa non raccoglie risorse e usa lo sprite CLOSED_POS.
---@param bag table La Bag of Crafting
---@param closed boolean true per chiuderla
function TBOI.FUNCS.set_bag_closed(bag, closed)
    bag.ability.extra.closed = closed or false
    if bag.children.center then
        bag.children.center:set_sprite_pos(closed and TBOI.BAG_OF_CRAFTING.CLOSED_POS or bag.config.center.pos)
    end
    bag:juice_up()
    card_eval_status_text(bag, 'extra', nil, nil, nil, {
        message = closed and 'Closed' or 'Opened',
        colour = G.C.FILTER,
    })
end
