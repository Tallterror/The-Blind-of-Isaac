TBOI.Back{
    key = "isaac",
    atlas = 'decks',
    pos = { x = 0, y = 0 },

    loc_txt = {
		  name = 'Innocence Deck',
		  text = {
        'Start with {C:attention,E:2}The D6'
		  }
	  },
    starting_jokers = { 'the_d_six' },

    apply = function(self, back)
      TBOI.FUNCS.init_health(0)
    end
}