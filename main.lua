TBOI = {}
TBOI.FUNCS = {}
TBOI.UIDEF = {}
tboi_config = SMODS.current_mod.config

local load_directory = assert(SMODS.load_file("src/loader.lua"))()

load_directory("src/records")
load_directory("src/functions")
load_directory("src/content")

-- Registra joker e mazzi nell'ordine di TBOI.JOKER_ORDER / TBOI.DECK_ORDER (vedi src/functions/registry.lua)
TBOI.FUNCS.register_all()

function SMODS.current_mod.reset_game_globals(run_start)
    G.FUNCS:increment_charge_on_round_end()
end