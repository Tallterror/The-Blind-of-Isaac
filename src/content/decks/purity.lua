TBOI.Back{
    key = "purity",
    atlas = 'decks',
    pos = { x = 1, y = 0 },

    loc_txt = {
		  name = 'Purity Deck',
		  text = {
        '+1 Red Heart',
        'Start with {C:attention,E:2}Yum Heart'
		  }
	  },
    starting_jokers = { 'yum_heart' },

    apply = function(self, back)
      TBOI.FUNCS.init_health(1)
    end
}