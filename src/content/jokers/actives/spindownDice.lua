TBOI.Joker{
	key = 'spindown_dice',
	loc_txt = {
		name = 'SpinDown Dice',
		text = {
			'Changes all',
			'not possessed Jokers',
			'IDs on screen by -1'
		}
	},
	config = {
		is_active = true,
		required_charge = 1,
		charge = 1,
		max_charge = 1,
		extra = {spindown = -1}
	},
	atlas = 'jokers',
	pos = {x = 0, y = 1},
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
					local previous = TBOI.FUNCS.spindown_result(other)
					if previous then
						TBOI.FUNCS.change_shop_joker(other, previous, area)
					else
						SMODS.destroy_cards(other)
					end
				end
			end,
			{G.shop_jokers,G.pack_cards,G.planetarium,G.treasure_room}
		)
	end
}