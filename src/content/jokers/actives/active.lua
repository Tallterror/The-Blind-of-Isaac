--New Active jokers area
function SMODS.current_mod.custom_card_areas(game)
    -- Larghezza fissa (1.5 volte il mazzo), indipendente dagli slot: con più carte si stringono dentro.
    -- La x è spostata a sinistra della larghezza aggiunta, così il bordo destro resta allineato al mazzo.
    local width = G.deck.T.w * 1.5
    game.actives = CardArea(
        G.deck.T.x + 0.1 - (width - G.deck.T.w), G.deck.T.y - 3.5,
        width, G.jokers.T.h,
        { card_limit = 1, type = 'joker', highlight_limit = 1 }
    )
    -- Come G.jokers/G.consumeables: i pulsanti vendi/usa vanno a destra della carta invece che sotto
    game.actives.config.align_buttons = true
end

--SMODS set_ability unisce la nuova ability alla vecchia: senza queste chiavi un joker attivo
--che cambia center (es. nei cicli del negozio) lascerebbe is_active/charge al nuovo joker
function SMODS.current_mod.set_ability_reset_keys()
    return { 'is_active', 'charge', 'required_charge', 'max_charge' }
end

--Check For Use Button
G.FUNCS.can_use_active = function(e)
    if e.config.ref_table:can_use_active() then
        e.config.colour = G.C.YELLOW
        e.config.button = 'use_active'
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

--Use Button Process
G.FUNCS.use_active = function(e)
    local card = e.config.ref_table
    local center = card.config.center
    -- Firma: use(self, card, context)
    --   self    = il center del joker (la definizione con la funzione use)
    --   card    = la carta che attiva l'effetto
    --   context = informazioni sull'attivazione
    local context = {
        using_active = true,
        area = card.area,
        charge = card.ability.charge,
        required_charge = card.ability.required_charge,
    }
    if center.use then
        center:use(card, context)
    end
    card.ability.charge = 0
end

--Increment Active jokers charge on round end
G.FUNCS.increment_charge_on_round_end = function()
    if G.actives and G.actives.cards then
        for i = 1, #G.actives.cards do
            if G.actives.cards[i].ability.is_active and G.actives.cards[i].increment_charge then
                G.actives.cards[i]:increment_charge()
            end
        end
    end
end
--Condizione di uso specifica del joker: se la definizione ha can_use_active(self, card),
--oltre alla carica serve che restituisca true
local Card_can_use_active = Card.can_use_active
function Card:can_use_active(...)
    if not Card_can_use_active(self, ...) then return false end
    -- Con lo sticker Crafted (card.ability.tboi_crafted) il joker attivo non si può usare
    if self.ability.tboi_crafted then return false end
    local center = self.config.center
    if center.can_use_active then
        return center:can_use_active(self) and true or false
    end
    return true
end
