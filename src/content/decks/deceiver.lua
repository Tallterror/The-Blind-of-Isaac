TBOI.Back{
    key = "the_deceiver",
    atlas = 'decks',
    pos = { x = 3, y = 1 },

    loc_txt = {
		  name = 'Deceiver Deck',
		  text = {
        'No Red Heart',
        '+2 Black Heart',
        'Start with {C:attention,E:2}Dark Arts'
		  }
	  },
    starting_jokers = { { key = 'dark_arts', stickers = {'eternal'}} },
    active_slots = 2,
    no_red_hearts = true,

    apply = function(self, back)
      TBOI.FUNCS.init_health(8)
    end
}