TBOI.Back{
      key = "the_broken",
      atlas = 'decks',
      pos = { x = 0, y = 1 },

      loc_txt = {
		name = 'Broken Deck',
		text = {
            'Better Destiny',
            '-1 Joker Slots',
            '{C:attention}-2 Hand Size'
		}
	},
      config = {
            hand_size = -2,
            joker_slot = -1,
      },
      apply = function(self, back)
            TBOI.FUNCS.init_health(0)
            G.GAME.total_options = 1
      end
     
}