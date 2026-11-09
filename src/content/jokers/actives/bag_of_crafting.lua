TBOI.Joker{
	key = 'bag_of_crafting',
	loc_txt = {
		name = 'Bag Of Crafting',
		text = {
			'Consumes {C:attention}8{} gained resources',
			'to craft a joker',
			'Active jokers crafted this way',
			'have the {C:}Crafted Stiker',
			'{C:inactive}Make your destiny',
			'{C:inactive}(#1#/#2# resources){}'
		}
	},
	loc_vars = function(self, info_queue, card)
		local extra = card.ability.extra
		local contents = type(extra) == 'table' and extra.contents or {}
		return { vars = { #contents, TBOI.BAG_OF_CRAFTING.CAPACITY } }
	end,
	config = {
		is_active = true,
		required_charge = 0,
		max_charge = 0,
		charge = 0,
		extra = { contents = {}, closed = false }, -- risorse raccolte e borsa chiusa (vedi src/functions/crafting.lua)
	},
	atlas = 'jokers',
	pos = {x = 1, y = 1},
	rarity = 3,
	-- Uso: se è piena crea il joker, altrimenti la chiude (le risorse non entrano più)
	-- o la riapre se era già chiusa. Lo stato è in card.ability.extra.closed.
	use = function(self, card, context)
		local contents = card.ability.extra.contents or {}
		if #contents >= TBOI.BAG_OF_CRAFTING.CAPACITY then
			TBOI.FUNCS.craft_from_bag(card)
		else
			TBOI.FUNCS.set_bag_closed(card, not card.ability.extra.closed)
		end
	end,

	-- Sprite della borsa chiusa: chiamata da SMODS a ogni set_sprites (anche al caricamento della run)
	-- Nota: quando una carta cambia center (es. nei cicli del negozio) set_sprites viene chiamata
	-- PRIMA che l'ability venga sostituita, quindi card.ability può essere ancora quella del joker
	-- precedente (es. Hiker ha extra = 5, un numero): serve controllare che extra sia una tabella.
	set_sprites = function(self, card, front)
		local extra = card.ability and card.ability.extra
		if type(extra) == 'table' and extra.closed and card.children.center then
			card.children.center:set_sprite_pos(TBOI.BAG_OF_CRAFTING.CLOSED_POS)
		end
	end,
}
