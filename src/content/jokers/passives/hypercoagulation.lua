TBOI.Joker{
	key = 'hypercoagulation',
	loc_txt = {
		name = 'Hypercoagulation',
		text = {
			'{C:green}#1# in #2#{} chance to',
			'heal half a red heart for',
			'hand played'
		}
	},
	config = {
		extra = { odds = 3 }, -- 1 possibilità su odds
	},
	atlas = 'jokers',
	pos = {x = 3, y = 1},
    rarity = 2,

	loc_vars = function(self, info_queue, card)
		-- Probabilità con i modificatori del gioco (es. Oops! All 6s, Lucky Penny)
		local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'tboi_hypercoagulation')
		return { vars = { numerator, denominator } }
	end,

	-- Per ogni mano giocata (dopo il punteggio): 1 possibilità su 3 di curare mezzo cuore rosso
	calculate = function(self, card, context)
		if context.after and not context.blueprint
		and SMODS.pseudorandom_probability(card, 'tboi_hypercoagulation', 1, card.ability.extra.odds, 'tboi_hypercoagulation') then
			TBOI.FUNCS.add_red_heart(1)
			return { message = '+1/2 Heart', colour = G.C.RED }
		end
	end,
}
