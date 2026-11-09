TBOI.Joker{
	key = 'pedestal',
	config = {
        extra = {
            key = nil,
            speed = 1,
            keys = {}
        }
	},
    no_collection = true,

    in_pool = function(self, args)
        return false
    end,

    update = function(self, card, dt)
        if G.GAME and G.GAME.TIMERS and G.GAME.TIMERS.TOTAL and #card.ability.extra.keys > 0 then
            local ability = card.ability.extra
            ability.key = ability.keys[math.floor(G.GAME.TIMERS.TOTAL * ability.speed % #ability.keys)+1]
            card:set_sprites(card.config.center)
        end
    end,
}