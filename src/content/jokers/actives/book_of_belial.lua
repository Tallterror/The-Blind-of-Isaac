TBOI.Joker{
	key = 'book_of_belial',
	loc_txt = {
		name = 'The Book Of Belial',
		text = {
			'On use:',
			'{C:white,X:red}X3{} Mult',
			'+{C:white,X:red}X2{} Mult after',
			'first use of round'
		}
	},
	config = {
		is_active = true,
		required_charge = 2,
		max_charge = 2,
		charge = 2,
		active = false,
		uses = 0
	},
	atlas = 'jokers',
	pos = {x = 1, y = 0},
	rarity = 2,
	use = function(self, card, context)
		card.ability.active = true
		card.ability.uses = card.ability.uses+1
	end,
	calculate = function(self, card, context)
		if card.ability.active and context.joker_main then
			local boost = SMODS:find_card('blood_of_the_martyr')
			if boost and #boost > 0 then
				return {
					xmult = 3 + 2*card.ability.uses
				}
			else
				return {
					xmult = 2 + 1*card.ability.uses
				}
			end
		end
		if context.end_of_round and context.main_eval then
			card.ability.active = false
			card.ability.uses = 0
		end
	end
}
