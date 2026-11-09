TBOI.Back{
    key = "the_hoarder",
    atlas = 'decks',
    pos = { x = 2, y = 1 },

    loc_txt = {
		  name = 'Hoarder Deck',
		  text = {
        '-1 Red Heart',
        '+1 Luck',
        'No Destiny',
        'Start with {C:attention,E:2}Bag of Crafting'
		  }
	  },
    starting_jokers = { { key = 'bag_of_crafting', stickers = { 'eternal' } } },
    ignore_joker_space = true, -- i joker si possono comprare/selezionare anche senza spazio (vengono distrutti subito)
    active_slots = 2, -- slot dei joker attivi

    apply = function(self, back)
      TBOI.FUNCS.init_health(2)
    end,

    calculate = function(self, back, context)
      -- Lo sticker Crafted (chiave tboi_crafted) è salvato in card.ability.tboi_crafted
      -- I joker creati da un joker di TBOI.HOARDER_COPY_SOURCES (es. la copia dell'Invisible Joker) restano
      if context.card_added and context.card.ability.set == 'Joker' and not context.card.ability.tboi_crafted
      and not context.card.ability.tboi_starting
      and not TBOI.hoarder_copying then
        TBOI.FUNCS.hoarder_reward(context.card)
        SMODS.destroy_cards(context.card)
      end
    end
}
-- Mentre un joker di TBOI.HOARDER_COPY_SOURCES calcola il suo effetto (es. l'Invisible Joker venduto
-- che duplica un joker), le carte aggiunte non vengono trasformate in risorse.
-- Il contesto card_added scatta dentro add_to_deck, quindi durante questa chiamata.
local Card_calculate_joker = Card.calculate_joker
function Card:calculate_joker(context, ...)
    if not (TBOI.HOARDER_COPY_SOURCES[self.config.center.key] and context and context.selling_self) then
        return Card_calculate_joker(self, context, ...)
    end
    local previous = TBOI.hoarder_copying
    TBOI.hoarder_copying = true
    local ret = { Card_calculate_joker(self, context, ...) }
    TBOI.hoarder_copying = previous
    return unpack(ret)
end
