function TBOI.FUNCS.init_health(id)
    G.GAME.health = {}
    if id==0 then
        TBOI.FUNCS.add_container('normal', 2)
        TBOI.FUNCS.add_container('normal', 2)
        TBOI.FUNCS.add_container('normal', 2)
    elseif id==1 then
        TBOI.FUNCS.add_container('normal', 2)
        TBOI.FUNCS.add_container('normal', 2)
        TBOI.FUNCS.add_container('normal', 2)
        TBOI.FUNCS.add_container('normal', 2)
    elseif id==2 then
        TBOI.FUNCS.add_container('normal', 2)
        TBOI.FUNCS.add_container('normal', 2)
    elseif id==3 then
        TBOI.FUNCS.add_container('normal', 2)
    elseif id==4 then
        TBOI.FUNCS.add_soul_heart('black')
        TBOI.FUNCS.add_soul_heart('black')
        TBOI.FUNCS.add_soul_heart('black')
    elseif id==5 then
        TBOI.FUNCS.add_container('normal', 2)
        TBOI.FUNCS.add_soul_heart('black')
        TBOI.FUNCS.add_soul_heart('black')
    elseif id==6 then
        TBOI.FUNCS.add_container('bone', 2)
        TBOI.FUNCS.add_container('bone', 2)
        TBOI.FUNCS.add_container('bone', 2)
    elseif id==7 then
        TBOI.FUNCS.add_container('normal', 2)
        TBOI.FUNCS.add_container('normal', 2)
        TBOI.FUNCS.add_soul_heart()
    elseif id==8 then
        TBOI.FUNCS.add_soul_heart('black')
        TBOI.FUNCS.add_soul_heart('black')
    end
        
end

function TBOI.FUNCS.add_container(c_type, fill_amount)
    c_type = c_type or 'normal'
    fill_amount = fill_amount or 1
    -- Mazzi con no_red_hearts: un contenitore normale diventa un soul heart intero,
    -- un contenitore d'osso resta vuoto
    if TBOI.FUNCS.deck_flag('no_red_hearts') then
        if c_type == 'normal' then
            TBOI.FUNCS.add_soul_heart('blue', 2)
            return
        end
        fill_amount = 0
    end
    G.GAME.health = G.GAME.health or {}
    local health = G.GAME.health

    -- Trova dove finiscono i contenitori e iniziano i cuori blu/neri
    local insert_idx = #health + 1
    if c_type == 'normal' then
        for i, slot in ipairs(health) do
            if slot.container == nil or slot.container == 'bone' then
                insert_idx = i
                break
            end
        end
    end

    local new_slot = {
        container = c_type,
        content = fill_amount > 0 and 'red' or nil,
        amount = fill_amount,
        overlay = nil
    }
    table.insert(health, insert_idx, new_slot)

    -- Cap massimo cuori
    if #health > TBOI.HEART_CONFIG.max_slots then
        table.remove(health, #health)
    end
    TBOI.FUNCS.refresh_heart_bar()
end

--- Aggiunge cuori senza contenitore (Blu o Neri) alla fine.
--- Se c'è già un mezzo cuore blu/nero (l'ultimo), viene completato prima di aggiungerne altri:
---   - mezzo dello stesso tipo: si completa, il resto si aggiunge dopo
---   - mezzo del tipo opposto + cuore intero raccolto: si completa (resta del suo tipo)
---     e si aggiunge mezzo cuore del tipo raccolto
---   - mezzo del tipo opposto + mezzo cuore raccolto: si completa e diventa del tipo raccolto
---@param s_type string 'blue' o 'black'
---@param amount number Mezzi cuori da aggiungere (2 = cuore intero)
function TBOI.FUNCS.add_soul_heart(s_type, amount)
    s_type = s_type or 'blue'
    amount = amount or 2
    G.GAME.health = G.GAME.health or {}
    local health = G.GAME.health

    -- Ultimo mezzo cuore senza contenitore
    local half
    for i = #health, 1, -1 do
        local slot = health[i]
        if slot.container == nil and slot.content and (slot.amount or 0) < 2 then
            half = slot
            break
        end
    end

    if half and amount > 0 then
        if half.content == s_type then
            half.amount = 2
            amount = amount - 1
        elseif amount == 1 then
            half.content = s_type
            half.amount = 2
            amount = 0
        else
            half.amount = 2
            amount = amount - 1
        end
    end

    while amount > 0 and #health < TBOI.HEART_CONFIG.max_slots do
        local piece = math.min(2, amount)
        table.insert(health, { container = nil, content = s_type, amount = piece, overlay = nil })
        amount = amount - piece
    end
    TBOI.FUNCS.refresh_heart_bar()
end


---@param overlay_type string Type of overlay heart to add ['eternal' | 'gold']
function TBOI.UIDEF.add_overlay(overlay_type)
    G.GAME.health = G.GAME.health or {}
    local target_idx = nil

    -- Cerca l'ultimo rosso/marcio
    if overlay_type == 'eternal' then
        for i = #G.GAME.health, 1, -1 do
            local heart = G.GAME.health[i]
            if heart.overlay == 'eternal' then
                heart.overlay = nil
                TBOI.FUNCS.add_container('normal', 0)
                TBOI.FUNCS.refresh_heart_bar()
                return
            end
            if heart.content == 'red' or heart.content == 'rotten' or heart.container == 'bone' then
                target_idx = i; break
            end
        end
        if not target_idx then
            for i = 1, #G.GAME.health, 1 do
                local heart = G.GAME.health[i]
                if heart.overlay == 'eternal' then
                    heart.overlay = nil
                    TBOI.FUNCS.add_container('normal', 0)
                    TBOI.FUNCS.refresh_heart_bar()
                    return
                end
                if G.GAME.health[i].content or G.GAME.health[i].container then
                    target_idx = i; break
                end
            end
        end
    else
        for i = #G.GAME.health, 1, -1 do
            if G.GAME.health[i].overlay == overlay_type then
                target_idx = i; break
            end
        end
    end
    if target_idx then
        G.GAME.health[target_idx].overlay = overlay_type
        TBOI.FUNCS.refresh_heart_bar()
    end
end

--- Al cambio di ante: ogni eternal heart posseduto viene rimosso
--- e al suo posto si aggiunge un contenitore vuoto.
--- Chiamata dall'hook di ease_ante (src/functions/hooks.lua).
function TBOI.FUNCS.convert_eternal_hearts()
    local health = G.GAME and G.GAME.health
    if not health then return end
    local converted = 0
    for _, slot in ipairs(health) do
        if slot.overlay == 'eternal' then
            slot.overlay = nil
            converted = converted + 1
        end
    end
    for _ = 1, converted do
        TBOI.FUNCS.add_container('normal', 0)
    end
    if converted > 0 then TBOI.FUNCS.refresh_heart_bar() end
end

--- Cura (riempie) i contenitori vuoti con cuori rossi
function TBOI.FUNCS.add_red_heart(amount)
    if TBOI.FUNCS.deck_flag('no_red_hearts') then return end -- mazzo senza cuori rossi
    G.GAME.health = G.GAME.health or {}
    local healed = 0.0

    for _, slot in ipairs(G.GAME.health) do
        if healed >= amount then break end
        -- Se è un contenitore e ha spazio...
        if slot.container and (slot.content == nil or (slot.content == 'red' and slot.amount < 2)) then
            local current = slot.amount or 0
            local to_heal = math.min(amount - healed, 2 - current)
            
            slot.content = 'red'
            slot.amount = current + to_heal
            healed = healed + to_heal
        end
    end
    TBOI.FUNCS.refresh_heart_bar()
end

--- Mette cuori marci nei contenitori: prima in quelli vuoti, poi al posto dei cuori rossi
function TBOI.FUNCS.add_rotten_heart(amount)
    if TBOI.FUNCS.deck_flag('no_red_hearts') then return end -- mazzo senza cuori rossi
    amount = amount or 1
    G.GAME.health = G.GAME.health or {}
    local given = 0
    for _, pass in ipairs({ 'empty', 'red' }) do
        for _, slot in ipairs(G.GAME.health) do
            if given >= amount then break end
            local matches = (pass == 'empty' and slot.content == nil) or (pass == 'red' and slot.content == 'red')
            if slot.container == 'normal' and matches then
                slot.content = 'rotten'
                slot.amount = 2
                given = given + 1
            end
        end
    end
    TBOI.FUNCS.refresh_heart_bar()
end

---@param amount int Ammount of health to damage for.
---@param ignore_protections boolean? Check if the damage can bypass immunities.
function TBOI.FUNCS.take_damage(amount, ignore_protections, ante_scaling)
    amount = amount or 1.0
    if ante_scaling == nil then
        ante_scaling = true
    end
    if ante_scaling and G.GAME.round_resets.ante > 6 and amount == 1 then
        amount = 2
    end
    G.GAME.health = G.GAME.health or {}
    local health = G.GAME.health

    for i = #health, 1, -1 do
        if amount <= 0 then break end
        local slot = health[i]

        if slot.overlay then
            if slot.overlay == 'eternal' then
                amount = amount - 1
            end
            slot.overlay = nil
        end    
        if slot.container == nil then
            -- Cuori Blu/Neri
            if slot.amount > amount then
                slot.amount = slot.amount - amount
                amount = 0.0
            else
                amount = amount - slot.amount
                table.remove(health, i)
            end
        elseif slot.content then
            if slot.amount > amount then
                slot.amount = slot.amount - amount
                amount = 0.0
            elseif slot.container == 'bone' and slot.amount < amount then
                amount = amount - slot.amount
                slot.content = nil
                slot.amount = 0.0
                table.remove(health, i)
            else
                amount = amount - slot.amount
                slot.content = nil
                slot.amount = 0.0
            end
        end
    end
    TBOI.FUNCS.refresh_heart_bar()
end


--- Vita totale rimasta (in mezzi cuori), cuori eterni inclusi
function TBOI.FUNCS.get_total_health()
    local total = 0.0
    for _, slot in ipairs(G.GAME.health or {}) do
        if slot.content then
            total = total + (slot.amount or 0)
        end
        if slot.overlay == 'eternal' then
            total = total + 1
        end
    end
    return total
end

--- Il giocatore è morto quando non ha più cuori
function TBOI.FUNCS.is_dead()
    if not (G.GAME and G.GAME.health) then return false end
    return TBOI.FUNCS.get_total_health() <= 0
end


--- Costruisce i nodi UI per la barra dei cuori, unendo dinamicamente gli sprite layer per layer
function TBOI.UIDEF.build_heart_bar_nodes()
    local cfg = TBOI.HEART_CONFIG
    local health = G.GAME.health or {}
    local rows, current_row = {}, {}

    for i, slot in ipairs(health) do
        if i > cfg.max_slots then break end

        local frames_to_draw = {}

        -- 1. BASE: Contenitore Vuoto (Normale o Osso)
        if slot.container == 'normal' or slot.container == 'bone' then
            table.insert(frames_to_draw, TBOI.FRAMES.empty)
        end

        -- 2. CONTENUTO
        if slot.content == 'red' then
            table.insert(frames_to_draw, slot.amount == 2 and TBOI.FRAMES.red_full or TBOI.FRAMES.red_half)
        elseif slot.content == 'blue' then
            table.insert(frames_to_draw, slot.amount == 2 and TBOI.FRAMES.blue_full or TBOI.FRAMES.blue_half)
        elseif slot.content == 'black' then
            table.insert(frames_to_draw, slot.amount == 2 and TBOI.FRAMES.black_full or TBOI.FRAMES.black_half)
        elseif slot.content == 'rotten' then
            table.insert(frames_to_draw, TBOI.FRAMES.rotten)
        end

        -- 3. OVERLAY 1: Osso (Va sempre *Sopra* il contenuto rosso per incorniciarlo)
        if slot.container == 'bone' then
            table.insert(frames_to_draw, TBOI.FRAMES.bone)
        end

        -- 4. OVERLAY 2: Oro / Eterno
        if slot.overlay == 'gold' then
            table.insert(frames_to_draw, TBOI.FRAMES.gold)
        elseif slot.overlay == 'eternal' then
            table.insert(frames_to_draw, TBOI.FRAMES.eternal)
        end

        -- Compone lo sprite in Balatro: il primo frame è il Parent, gli altri sono Children minori sovrapposti
        local base_sprite = nil
        if #frames_to_draw > 0 then
            base_sprite = Sprite(0, 0, cfg.icon_w * cfg.icon_scale, cfg.icon_h * cfg.icon_scale, G.ASSET_ATLAS[cfg.atlas_key], frames_to_draw[1])
            for j = 2, #frames_to_draw do
                local child_sprite = Sprite(0, 0, cfg.icon_w * cfg.icon_scale, cfg.icon_h * cfg.icon_scale, G.ASSET_ATLAS[cfg.atlas_key], frames_to_draw[j])
                -- Aggancia lo sprite per creare una sovrapposizione perfetta
                child_sprite:set_role({role_type = 'Minor', major = base_sprite})
                base_sprite.children[#base_sprite.children+1] = child_sprite
            end
        else
            base_sprite = Sprite(0, 0, cfg.icon_w * cfg.icon_scale, cfg.icon_h * cfg.icon_scale, G.ASSET_ATLAS[cfg.atlas_key], TBOI.FRAMES.empty)
        end

        table.insert(current_row, {
            n = G.UIT.C,
            config = { id = 'tboi_heart_slot_'..i, align = 'cm', padding = 0.01 },
            nodes = {
                {n = G.UIT.O, config = {object = base_sprite}}
            }
        })

        -- Vai a capo se necessario
        if i % cfg.icons_per_row == 0 or i == #health then
            table.insert(rows, {
                n = G.UIT.R,
                config = { align = 'cm', padding = 0.01, id = 'tboi_heart_row_'..(#rows + 1) },
                nodes = current_row
            })
            current_row = {}
        end
    end

    return
        {n=G.UIT.R, config={align = "lm", colour = darken(G.C.BLACK, 0.1), r = 0.1, emboss = 0.05, padding = 0.03}, nodes={
            { n = G.UIT.C, config = { align = 'cm', id = 'tboi_heart_bar', padding = 0.05, minh = 1.1, minw = 1 }, nodes = rows}
        }}
end

--- Aggiorna la barra dinamicamente
function TBOI.FUNCS.refresh_heart_bar()
    if not G.HUD then return end

    -- Troviamo il contenitore principale dei cuori
    local bar = G.HUD:get_UIE_by_ID('tboi_heart_bar')
    if not bar then return end

    -- 1. SVUOTIAMO LA BARRA: Rimuoviamo solo le righe di cuori vecchie
    -- remove() distrugge l'elemento ma non lo toglie da parent.children:
    -- senza svuotare la lista le righe vecchie continuano a occupare spazio nel layout
    if bar.children then
        for i = #bar.children, 1, -1 do
            bar.children[i]:remove()
        end
    end
    bar.children = {}

    -- 2. Generiamo la nuova configurazione dei cuori
    -- build_heart_bar_nodes() ritorna R(sfondo) -> C(tboi_heart_bar) -> righe
    local new_bar_def = TBOI.UIDEF.build_heart_bar_nodes()
    local rows = new_bar_def.nodes and new_bar_def.nodes[1] and new_bar_def.nodes[1].nodes or {}

    -- 3. RIEMPIAMO LA BARRA e ricalcoliamo il layout una sola volta
    for _, row_def in ipairs(rows) do
        G.HUD:set_parent_child(row_def, bar)
    end
    G.HUD:recalculate()
end