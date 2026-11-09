-- Esclude tutti i joker vanilla dalla generazione casuale (negozio, buste, tag, poll_object...).
-- Restano creabili esplicitamente per chiave (es. SMODS.add_card{key = 'j_joker'}).

local vanilla_jokers = {}
for key, center in pairs(G.P_CENTERS) do
    if center.set == 'Joker' and not center.mod and not center.original_mod then
        vanilla_jokers[#vanilla_jokers + 1] = key
    end
end

for _, key in ipairs(vanilla_jokers) do
    SMODS.Joker:take_ownership(key, {
        prefix_config = { key = false }, -- la chiave è già completa ('j_...')
        in_pool = function(self, args)
            return true
        end,
    }, true)
end
