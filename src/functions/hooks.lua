local G_ease_ante = ease_ante
function ease_ante(mod)
    G_ease_ante(mod)

    -- ease_ante cambia G.GAME.round_resets.ante dentro un evento: qui c'è ancora il valore vecchio
    local old_ante = G.GAME.round_resets.ante or 0
    TBOI.FUNCS.change_shop_ante(old_ante, old_ante + (mod or 0))
    TBOI.FUNCS.convert_eternal_hearts()

    if G.GAME.can_planetarium_change then
        G.GAME.planetarium = G.GAME.planetarium + 20
    end
end

-- spindown Info Hook
local G_generate_card_ui = generate_card_ui
function generate_card_ui(...)
    local _c = select(1, ...)
    
    local rets = {G_generate_card_ui(...)}
    local ui_table = rets[1]

    if type(_c) == 'table' and _c.set == 'Joker' and type(ui_table) == 'table' and ui_table.info then
        
        local spindown = SMODS.find_card('j_tboi_spindown_dice', true) 
        
        if spindown and #spindown > 0 then
            
            local all_found = TBOI.FUNCS.operate_all_areas(function(area)
            local found = nil
            if area and area.cards then
                 -- ERRORE CORRETTO: usa area.cards invece di G.shop_jokers.cards
                for _, card_iteration in ipairs(area.cards) do
                    if card_iteration.config.center.key == _c.key then
                        found = card_iteration
                        break
                    end
                end
            end
            return found
            end,
            {G.treasure_room, G.planetarium, G.shop_jokers, G.pack_cards})

            local found_Card = nil
            if #all_found > 0 then
                found_Card = all_found[1]
            end

            if found_Card then
              local previous = TBOI.FUNCS.spindown_result(found_Card)
              if previous == nil then
                 previous = 'Nothing'
             else
                 previous = localize{type = "name_text", set = 'Joker', key = previous}
             end
    
             local tooltip_extra = {
                 key = "spindown_info",
                    set = "Other",
                    vars = { previous }
                }
    
                G_generate_card_ui(tooltip_extra, ui_table)
            end
        end
    end
    return unpack(rets)
end

local G_start_run = Game.start_run
function Game:start_run(args)
    G_start_run(self, args)
    TBOI.FUNCS.set_up_pools()
    -- CardArea:load sostituisce config con quello salvato: i salvataggi vecchi non hanno align_buttons
    if G.actives then G.actives.config.align_buttons = true end
    -- Solo su una run nuova: su una run caricata tboi_shop_state arriva dal salvataggio
    -- (pagine salvate, sblocchi...) e non va azzerato
    if not G.GAME.tboi_shop_state then
        G.GAME.tboi_shop_state = {}
        G.GAME.tboi_shop_state.unlocked = {}
        G.GAME.tboi_shop_state.unlocked['treasure'] = true
    end
    G.GAME.tboi_shop_state.unlocked = G.GAME.tboi_shop_state.unlocked or {}
    if G.GAME.can_planetarium_change == nil then G.GAME.can_planetarium_change = true end
end

-- Mani giocate con 0 mani rimaste: niente decremento, ma si prende danno
local G_ease_hands_played = ease_hands_played
function ease_hands_played(mod, instant)
    if TBOI.skip_hand_decrement and (mod or 0) < 0 then return end
    return G_ease_hands_played(mod, instant)
end

local G_play_cards_from_highlighted = G.FUNCS.play_cards_from_highlighted
G.FUNCS.play_cards_from_highlighted = function(e)
    if G.play and G.play.cards[1] then return end

    local hands_left = G.GAME.current_round.hands_left
    -- Si prende danno giocando l'ultima mano (1 rimasta) e ogni mano giocata dopo (0 rimaste).
    -- Il danno viene risolto dopo il punteggio, in Game:update_hand_played (vedi lovely/health.toml)
    TBOI.overtime_hand = hands_left <= 1

    -- Con 0 mani il contatore non scende sotto zero
    TBOI.skip_hand_decrement = hands_left <= 0
    G_play_cards_from_highlighted(e)
    TBOI.skip_hand_decrement = nil
end

-- Chiamata dopo il punteggio della mano: se era giocata con 1 o 0 mani rimaste e il blind non è battuto, si prende danno
function TBOI.FUNCS.resolve_overtime_hand()
    if not TBOI.overtime_hand then return end
    TBOI.overtime_hand = nil

    local _to_big = to_big or function(x) return x end
    if G.GAME.chips - G.GAME.blind.chips < _to_big(0) then
        TBOI.FUNCS.take_damage(TBOI.HEART_CONFIG.overtime_damage)
        play_sound('tarot1', 0.8)
    end
end


function create_UIBox_HUD()
    local scale = 0.4
    local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)
 
    local contents = {}
 
    local spacing = 0.08
    local temp_col = G.C.DYN_UI.BOSS_MAIN
    local temp_col2 = G.C.DYN_UI.BOSS_DARK
 
    local bf = TBOI.CFG.button_scale or 1
    local bf_w = bf + (1 - bf) * 0.5
 
    contents.round = {
        {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.C, config={align = "cm", padding = 0.05, minw = 1.45*2 + spacing, minh = 1.15, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
                {n=G.UIT.R, config={align = "cm"}, nodes={
                    {n=G.UIT.C, config={align = "cm", r = 0.1, minw = 1.28*2+spacing, minh = 1, colour = temp_col2}, nodes={
                        {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'dollars', prefix = localize('$')}}, maxw = 1.35, colours = {G.C.MONEY}, font = G.LANGUAGES['en-us'].font, shadow = true,spacing = 2, bump = true, scale = 2.2*scale}), id = 'dollar_text_UI'}}
                    }},
                }},
            }},
        }},
        {n=G.UIT.R, config={minh = spacing},nodes={}},
        {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.C, config={id = 'hud_ante',align = "cm", padding = 0.05, minw = 1.45, minh = 1, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
                {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
                    {n=G.UIT.T, config={text = localize('k_ante'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                }},
                {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1.2, colour = temp_col2}, nodes={
                    {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME.round_resets, ref_value = 'ante'}}, colours = {G.C.IMPORTANT},shadow = true, font = G.LANGUAGES['en-us'].font, scale = 2*scale}),id = 'ante_UI_count'}},
                    {n=G.UIT.T, config={text = " ", scale = 0.3*scale}},
                    {n=G.UIT.T, config={text = "/ ", scale = 0.7*scale, colour = G.C.WHITE, shadow = true}},
                    {n=G.UIT.T, config={ref_table = G.GAME, ref_value='win_ante', scale = scale, colour = G.C.WHITE, shadow = true}}
                }},
            }},
            {n=G.UIT.C, config={minw = spacing},nodes={}},
            {n=G.UIT.C, config={align = "cm", padding = 0.05, minw = 1.45, minh = 1, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
                {n=G.UIT.R, config={align = "cm", maxw = 1.35}, nodes={
                    {n=G.UIT.T, config={text = localize('k_round'), minh = 0.33, scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                }},
                {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1.2, colour = temp_col2, id = 'row_round_text'}, nodes={
                    {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'round'}}, colours = {G.C.IMPORTANT},shadow = true, scale = 2*scale}),id = 'round_UI_count'}},
                }},
            }},
        }},
    }
 

    contents.hearts_row = TBOI.UIDEF.build_heart_bar_nodes()
 
    contents.counters_row = {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.C, config={id = 'hud_hands',align = "cm", padding = 0.05, minw = 1.1, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
                {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
                    {n=G.UIT.T, config={text = localize('k_hud_hands'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                }},
                {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1, colour = temp_col2}, nodes={
                    {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME.current_round, ref_value = 'hands_left'}}, font = G.LANGUAGES['en-us'].font, colours = {G.C.BLUE},shadow = true, rotate = true, scale = 2*scale}),id = 'hand_UI_count'}},
                }}
            }},
            {n=G.UIT.C, config={minw = spacing},nodes={}},
            {n=G.UIT.C, config={id = 'hud_discards',align = "cm", padding = 0.05, minw = 1.1, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
                {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
                    {n=G.UIT.T, config={text = localize('k_hud_discards'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                }},
                {n=G.UIT.R, config={align = "cm"}, nodes={
                    {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1, colour = temp_col2}, nodes={
                        {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME.current_round, ref_value = 'discards_left'}}, font = G.LANGUAGES['en-us'].font, colours = {G.C.RED},shadow = true, rotate = true, scale = 2*scale}),id = 'discard_UI_count'}},
                    }}
                }},
            }},
            {n=G.UIT.C, config={minw = spacing},nodes={}},
            {n=G.UIT.C, config={id = 'hud_bombs',align = "cm", padding = 0.05, minw = 1.1, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
                {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
                    {n=G.UIT.T, config={text = localize('k_hud_bombs'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                }},
                {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1, colour = temp_col2}, nodes={
                    {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'bombs'}}, font = G.LANGUAGES['en-us'].font, colours = {G.C.PURPLE},shadow = true, rotate = true, scale = 2*scale}),id = 'bomb_UI_count'}},
                }}
            }},
            {n=G.UIT.C, config={minw = spacing},nodes={}},
            {n=G.UIT.C, config={id = 'hud_keys',align = "cm", padding = 0.05, minw = 1.1, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
                {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
                    {n=G.UIT.T, config={text = localize('k_hud_keys'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                }},
                {n=G.UIT.R, config={align = "cm"}, nodes={
                    {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1, colour = temp_col2}, nodes={
                        {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'keys'}}, font = G.LANGUAGES['en-us'].font, colours = {G.C.ORANGE},shadow = true, rotate = true, scale = 2*scale}),id = 'key_UI_count'}},
                    }}
                }},
            }}
    }}
 
    contents.hand =
        {n=G.UIT.R, config={align = "cm", id = 'hand_text_area', colour = darken(G.C.BLACK, 0.1), r = 0.1, emboss = 0.05, padding = 0.03}, nodes={
            {n=G.UIT.C, config={align = "cm"}, nodes={
              {n=G.UIT.R, config={align = "cm", minh = 1.1}, nodes={
                {n=G.UIT.O, config={id = 'hand_name', func = 'hand_text_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "handname_text"}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, float = true, scale = scale*1.4})}},
                {n=G.UIT.O, config={id = 'hand_chip_total', func = 'hand_chip_total_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "chip_total_text"}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, float = true, scale = scale*1.4})}},
                {n=G.UIT.T, config={ref_table = G.GAME.current_round.current_hand, ref_value='hand_level', scale = scale, colour = G.C.UI.TEXT_LIGHT, id = 'hand_level', shadow = true}}
              }},
              {n=G.UIT.R, config={align = "cm", minh = 1, padding = 0.1}, nodes={
                {n=G.UIT.C, config={align = "cr", minw = 2, minh =1, r = 0.1,colour = G.C.UI_CHIPS, id = 'hand_chip_area', emboss = 0.05}, nodes={
                    --{n=G.UIT.O, config={func = 'flame_handler',no_role = true, id = 'flame_chips', object = Moveable(0,0,0,0), w = 0, h = 0}},
                    {n=G.UIT.O, config={id = 'hand_chips', func = 'hand_chip_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "chip_text"}}, colours = {G.C.UI.TEXT_LIGHT}, font = G.LANGUAGES['en-us'].font, shadow = true, float = true, scale = scale*2.3})}},
                    {n=G.UIT.B, config={w=0.1,h=0.1}},
                }},
                {n=G.UIT.C, config={align = "cm"}, nodes={
                  {n=G.UIT.T, config={text = "X", lang = G.LANGUAGES['en-us'], scale = scale*2, colour = G.C.UI_MULT, shadow = true}},
                }},
                {n=G.UIT.C, config={align = "cl", minw = 2, minh=1, r = 0.1,colour = G.C.UI_MULT, id = 'hand_mult_area', emboss = 0.05}, nodes={
                  --{n=G.UIT.O, config={func = 'flame_handler',no_role = true, id = 'flame_mult', object = Moveable(0,0,0,0), w = 0, h = 0}},
                  {n=G.UIT.B, config={w=0.1,h=0.1}},
                  {n=G.UIT.O, config={id = 'hand_mult', func = 'hand_mult_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "mult_text"}}, colours = {G.C.UI.TEXT_LIGHT}, font = G.LANGUAGES['en-us'].font, shadow = true, float = true, scale = scale*2.3})}},
                }}
              }}
            }}
          }}
 
    contents.dollars_chips = {n=G.UIT.R, config={align = "cm",r=0.1, padding = 0,colour = G.C.DYN_UI.BOSS_MAIN, emboss = 0.05, id = 'row_dollars_chips'}, nodes={
        {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
            {n=G.UIT.C, config={align = "cm", minw = 1.3}, nodes={
                {n=G.UIT.R, config={align = "cm", padding = 0, maxw = 1.3}, nodes={
                    {n=G.UIT.T, config={text = localize('k_round'), scale = 0.42, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
                }},
                {n=G.UIT.R, config={align = "cm", padding = 0, maxw = 1.3}, nodes={
                    {n=G.UIT.T, config={text =localize('k_lower_score'), scale = 0.42, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
                }}
            }},
            {n=G.UIT.C, config={align = "cm", minw = 3.3, minh = 0.7, r = 0.1, colour = G.C.DYN_UI.BOSS_DARK}, nodes={
                {n=G.UIT.O, config={w=0.5,h=0.5 , object = stake_sprite, hover = true, can_collide = false}},
                {n=G.UIT.B, config={w=0.1,h=0.1}},
                {n=G.UIT.T, config={ref_table = G.GAME, ref_value = 'chips_text', lang = G.LANGUAGES['en-us'], scale = 0.85, colour = G.C.WHITE, id = 'chip_UI_count', func = 'chip_UI_set', shadow = true}}
            }}
        }}
    }}
 
    contents.buttons = {
        {n=G.UIT.C, config={align = "cm", r=0.1, colour = G.C.CLEAR, shadow = true, id = 'button_area', padding = 0.2}, nodes={
            {n=G.UIT.R, config={id = 'run_info_button', align = "cm", minh = 1.5*bf, minw = 1.5*bf_w, padding = 0.05*bf, r = 0.1, hover = true, colour = G.C.RED, button = "run_info", shadow = true}, nodes={
                {n=G.UIT.R, config={align = "cm", padding = 0, maxw = 1.4}, nodes={
                    {n=G.UIT.T, config={text = localize('b_run_info_1'), scale = 1.2*scale*bf, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
                }},
                {n=G.UIT.R, config={align = "cm", padding = 0, maxw = 1.4}, nodes={
                    {n=G.UIT.T, config={text = localize('b_run_info_2'), scale = 1*scale*bf, colour = G.C.UI.TEXT_LIGHT, shadow = true, focus_args = {button = G.F_GUIDE and 'guide' or 'back', orientation = 'bm'}, func = 'set_button_pip'}}
                }}
            }},
            {n=G.UIT.R, config={align = "cm", minh = 1.5*bf, minw = 1.5*bf_w, padding = 0.05*bf, r = 0.1, hover = true, colour = G.C.ORANGE, button = "options", shadow = true}, nodes={
                {n=G.UIT.C, config={align = "cm", maxw = 1.4, focus_args = {button = 'start', orientation = 'bm'}, func = 'set_button_pip'}, nodes={
                    {n=G.UIT.T, config={text = localize('b_options'), scale = scale*bf, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
                }},
            }}
        }}
    }
    return {n=G.UIT.ROOT, config = {align = "cm", padding = 0.03, colour = G.C.UI.TRANSPARENT_DARK}, nodes={
        {n=G.UIT.R, config = {align = "cm", padding= 0.05, colour = G.C.DYN_UI.MAIN, r=0.1}, nodes={
            {n=G.UIT.R, config={align = "cm", colour = G.C.DYN_UI.BOSS_DARK, r=0.1, minh = 30, padding = 0.08}, nodes={
                {n=G.UIT.R, config={align = "cm", minh = 0.3}, nodes={}},
                {n=G.UIT.R, config={align = "cm", id = 'row_blind', minw = 1, minh = 3.75}, nodes={
                    -- Punto di aggancio di G.HUD_blind (il cartello del blind durante il round), vedi Game:start_run
                    {n=G.UIT.B, config={w=0, h=3.64, id = 'row_blind_bottom'}, nodes={}}
                }},
                contents.dollars_chips,
                contents.hand,
                contents.hearts_row,
                contents.counters_row,
                {n=G.UIT.R, config={align = "cm", id = 'row_round'}, nodes={
                    {n=G.UIT.C, config={align = "cm"}, nodes=contents.buttons},
                    {n=G.UIT.C, config={align = "cm"}, nodes=contents.round}
                }},
            }}
        }}
    }}
end

-- La pagina aperta va salvata anche quando il gioco salva la run, non solo al cambio pagina,
-- altrimenti uscendo dalla partita mentre è aperta si perde il suo contenuto
local G_save_run = save_run
function save_run(...)
    if TBOI.active_tab and G.GAME and G.GAME.tboi_shop_state then
        TBOI.save_tab_area(TBOI.active_tab)
    end
    return G_save_run(...)
end

local G_FUNCS_toggle_shop = G.FUNCS.toggle_shop
function G.FUNCS.toggle_shop(e)
    if TBOI.active_tab then
        TBOI.save_tab_area(TBOI.active_tab)
    end
    return G_FUNCS_toggle_shop(e)
end

local game_update = Game.update
function Game:update(dt)
    game_update(self, dt)
    if G then
    TBOI.FUNCS.operate_all_areas(
        TBOI.FUNCS.cycle_options,
        {G.shop_jokers,G.pack_cards,G.planetarium,G.treasure_room}
    )
    end
end
