TBOI.Back{
    key = "treachery",
    atlas = 'decks',
    pos = { x = 3, y = 0 },

    loc_txt = {
		  name = 'treachery Deck',
		  text = {
        '-2 Red Heart',
        'Start with {C:attention,E:2}The Book of Belial'
		  }
	  },
    starting_jokers = { 'book_of_belial' },

    apply = function(self, back)
      TBOI.FUNCS.init_health(3)
    end
}