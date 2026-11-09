TBOI.Joker{
	key = 'dark_arts',
	loc_txt = {
		name = 'Dark Arts',
		text = {
			'On use:',
			'+{C:white,X:mult}X#1#{} Mult for',
            'card discarded before playing',
            '{s:0.8}resets if not active and using discards',
            '{C:inactive}(Currently {C:white,X:mult}X#2#{} Mult{C:inactive})'
		}
	},
    loc_vars = function(self, info_queue, card)
        return {vars = {
            card.ability.extra.xmult,
            card.ability.extra.discards *0.1 + 1
        }}
    end,
	config = {
		is_active = true,
		required_charge = 2,
		max_charge = 2,
		charge = 2,
        extra = {
            xmult = 0.1,
            active = false,
		    discards = 0,
        }

	},
	atlas = 'jokers',
	pos = {x = 2, y = 0},
    rarity = 3,
	use = function(self, card, context)
		card.ability.extra.active = true
	end,
	calculate = function(self, card, context)
        if context.discard then
            if card.ability.extra.active then
                card.ability.extra.discards = card.ability.extra.discards + 1
            elseif card.ability.extra.discards > 0 then
                card.ability.extra.discards = 0
                card.ability.extra.last_discards = 0
                return {message = 'Reset'}
            end
        end

        if context.joker_main and card.ability.extra.discards > 0 then
            return {
                xmult = 1 + card.ability.extra.xmult * card.ability.extra.discards
            }
        end
        if context.after or context.end_of_round and context.main_eval then
            card.ability.extra.active = false
        end
	end
}
