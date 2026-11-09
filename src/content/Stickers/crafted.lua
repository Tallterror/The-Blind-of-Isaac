SMODS.Sticker{
    key = 'crafted',
    loc_txt = {
		name = 'Crafted',
		text = {
            '{C:negative}+1 Joker Slot',
            'Cant score or use',
            'Remove this sticker if slots are available',
            'Destroy this Joker at ante change',
		},
            label = 'Crafted'
    },
    badge_colour = HEX('62D497'),
    atlas = 'stickers',
    pos = { x = 0, y = 0 },
    config = {crafted = true, card_limit = 1},
    sets = {Joker = true, Active = true},
    rate = 0,
    never_scores = true,

    calculate = function(self, card, context)
      
      if context.ante_change and context.ante_change ~= 0 then
            SMODS.destroy_cards(card)
      end

      local area = card.area
      if area and area.cards and area.tboi_crafted_removed_at ~= G.TIMERS.UPTIME then
            local first
            for _, other in ipairs(area.cards) do
                  if other.ability.tboi_crafted then first = other break end
            end
            if first == card and #area.cards < area.config.card_limit then
                  area.tboi_crafted_removed_at = G.TIMERS.UPTIME
                  card:remove_sticker('tboi_crafted')
            end
      end
    end
}