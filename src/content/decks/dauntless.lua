TBOI.Back{
    key = "the_dauntless",
    atlas = 'decks',
    pos = { x = 1, y = 1 },

    loc_txt = {
		  name = 'Dauntless Deck',
		  text = {
        '+1 Red Heart?',
        'Start with {C:attention,E:2}Yum Heart',
        'Start with {C:attention,E:2}Hypercoagulation'
		  }
	  },
    starting_jokers = {{ key = 'yum_heart' , stickers = { 'eternal' } },{key = 'hypercoagulation', stickers = {'eternal'}}},
    active_slots = 2,

    apply = function(self, back)
      TBOI.FUNCS.init_health(1)
    end,

    calculate = function(self, card, context)
      if G.GAME.hands_played % 2 == 0 and context.after and TBOI.FUNCS.get_total_health() > 4 then
        TBOI.FUNCS.take_damage(1, true, false)
      end
    end
}