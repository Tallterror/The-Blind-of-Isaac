function G.UIDEF.create_select_card_ui(card, type, area)
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.2,
        blocking = false,
        blockable = false,
        func = (function()
            if card.opening then return false end 
            
            local select_button = {
                n = G.UIT.ROOT, config = {align = "bm", colour = G.C.CLEAR}, nodes = {
                    {
                        n = G.UIT.C, 
                        config = {
                            ref_table = card, 
                            align = "bm", 
                            maxw = 1.5, 
                            padding = 0.1, 
                            r = 0.08, 
                            minw = 1.5, 
                            minh = 0.75, 
                            hover = true, 
                            shadow = true, 
                            colour = G.C.UI.BACKGROUND_INACTIVE, 
                            one_press = true, 
                            button = 'tboi_select_card', 
                            func = 'tboi_can_select_card'
                        }, 
                        nodes = {
                            {n = G.UIT.T, config = {text = localize('b_select'), colour = G.C.UI.TEXT_LIGHT, scale = 0.45, shadow = true}}
                        }
                    }
                }
            }

            card.children.buy_button = UIBox{
                definition = select_button,
                config = {
                    align = "bm",
                    offset = {x = 0, y = -0.3},
                    major = card,
                    bond = 'Weak',
                    parent = card
                }
            }
            return true
        end)
    }))
end

