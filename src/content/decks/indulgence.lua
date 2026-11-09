TBOI.Back{
    key = "indulgence",
    atlas = 'decks',
    pos = { x = 2, y = 0 },

    loc_txt = {
		  name = 'Indulgence Deck',
		  text = {
        '-1 Red Heart',
        '+1 Luck'
		  }
	  },

    apply = function(self, back)
      TBOI.FUNCS.init_health(2)
    end
}