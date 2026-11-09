TBOI.Joker{
	key = 'yum_heart',
	loc_txt = {
		name = 'Yum Heart',
		text = {
			'Heals for a red heart',
		}
	},
	config = {
		is_active = true,
		required_charge = 2,
		max_charge = 2,
		charge = 2,
	},
	atlas = 'jokers',
	pos = {x = 3, y = 0},
    rarity = 2,
	use = function(self, card, context)
		TBOI.FUNCS.add_red_heart(2)
	end,
}
