TBOI.Joker{
	key = 'the_d_six',
	loc_txt = {
		name = 'The D6',
		text = {
			'Rerols every',
			'not possessed Joker',
			'on screen'
		}
	},
	config = {
		is_active = true,
		required_charge = 1,
		max_charge = 1,
		charge = 1
	},
	atlas = 'jokers',
	pos = {x = 0, y = 0},
	cost = 15,
	rarity = 4,
	use = function(self, card, context)
		TBOI.FUNCS.operate_all_areas(
			function(area)
				local cards = {}
				for _, other in ipairs(area.cards or {}) do
					if other.ability.set == 'Joker' then
						table.insert(cards, other)
					end
				end
				for _, other in ipairs(cards) do
					TBOI.FUNCS.change_shop_joker(other, nil, area)
				end
			end,
			{G.shop_jokers,G.pack_cards,G.planetarium,G.treasure_room}
		)
	end
}
