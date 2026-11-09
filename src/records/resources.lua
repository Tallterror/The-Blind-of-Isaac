-- Costanti delle risorse (bombe, chiavi). Il codice che le usa è in src/functions/resources.lua

TBOI.RESOURCES = {
    {key = 'nothing',          name = 'Nothing'},
    {key = 'poop',             name = 'Poop'},              --Da non implementare
    {key = 'dollar',           name = 'Penny'},             --Implementato
    {key = 'double_penny',     name = 'Double Penny'},      --2 dollar
    {key = 'key',              name = 'Key'},               --Implementato
    {key = 'key_ring',         name = 'Key Ring'},          --2 key
    {key = 'bomb',             name = 'Bomb'},              --Implementato
    {key = 'double_bomb',      name = 'Double Bomb'},       --2 bomb
    {key = 'red_heart',        name = 'Red Heart'},         --Carattere 'H' rosso, ridà 2 punti vita rossi
    {key = 'half_red_heart',   name = 'Half Red Heart'},    --Carattere 'h' rosso, ridà 1 punto vita rosso
    {key = 'double_red_heart', name = 'Double Red Heart'},  --2 red heart
    {key = 'rotted_heart',     name = 'Rotten Heart'},      --Carattere 'H' verde, dà un rotten heart
    {key = 'tarot_card',       name = 'Tarot'},             --Carattere 'c' marrone, dà un 
    {key = 'playing_card',     name = 'Playing Card'},      --Carattere 'c' rosso, Dà una carta casuale da aggiungere al mazzo
    {key = 'pill',             name = 'Pill'},              --Da non implementare
    {key = 'horse_pill',       name = 'Horse Pill'},        --Da non implementare
    {key = 'special_card',     name = 'Special Card'},      --Dà una carta di TBOI.SPECIAL_CARDS (quando esisteranno)
    {key = 'micro_battery',    name = 'Micro Battery'},     --Carattere 'b' grigio, ridà una carica del primo attivo nell'area
    {key = 'cracked_key',      name = 'Cracked Key'},       --Da non implementare
    {key = 'nickel',           name = 'Nickel'},            --Carattere '$' grigio, dà 5 dollar
    {key = 'soul_heart',       name = 'Soul Heart'},        --Carattere 'H' azzurro, dà un soul heart
    {key = 'half_soul_heart',  name = 'Half Soul Heart'},   --Carattere 'h' azzurro, dà un mezzo soul heart
    {key = 'rune',             name = 'Rune'},              --Da non implementare
    {key = 'lil_battery',      name = "Lil' Battery"},      --Carattere 'b' giallo, Carica del tutto il primo attivo nell'area
    {key = 'dice_shard',       name = 'Dice Shard'},        --Da non implementare
    {key = 'black_heart',      name = 'Black Heart'},       --Carattere 'H' grigio, dà un black heart
    {key = 'half_black_heart', name = 'Half Black Heart'},  --Carattere 'h' grigio, dà un mezzo black_heart
    {key = 'eternal_heart',    name = 'Eternal Heart'},     --Carattere 'h' bianco, dà un eternal heart
    {key = 'bone_heart',       name = 'Bone Heart'},        --Carattere 'h' grigio chiaro, dà un bone heart
    {key = 'charged_key',      name = 'Charged Key'},       --Carattere 'A' giallo pallido, dà una chiave e carica il primo attivo
    {key = 'dime',             name = 'Dime'},              --Carattere '$' bianco, dà 10 dollar
    {key = 'golden_heart',     name = 'Golden Heart'},      --Carattere 'H' d'oro, dà un golden_heart
    {key = 'golden_key',       name = 'Golden Key'},        --Carattere 'A' d'oro, imposta infinite chiavi per l'ante attuale
    {key = 'golden_bomb',      name = 'Golden Bomb'},       --Carattere 'B' d'oro, imposta infinite bombe per l'ante attuale
    {key = 'golden_penny',     name = 'Golden Penny'},      --Carattere '$' giallo, dà da 0 a 25 dollari
    {key = 'golden_pill',      name = 'Golden Pill'},       --Da non implementare
    {key = 'golden_battery',   name = 'Golden Battery'},    --Carattere 'b' d'oro, Carica tutti gli attivi, subisci 1 cuore di danno (si rimane a mezzo cuore)
    {key = 'lucky_penny',      name = 'Lucky Penny'},       --Carattere '$' verde, 1 dollar e +1 fortuna (la fortuna aumenta di 1 la possibilità di attivare effetti, simile a oops all sixes)
    {key = 'mega_battery',     name = 'Mega Battery'},      --Carattere 'b' grigio chiaro, dà il doppio delle cariche massime al primo attivo
    {key = 'mega_bomb',        name = 'Mega Bomb'},         --Da non implementare
}

-- Categorie delle risorse. Il tiro avviene in due fasi:
--   1. si sceglie la categoria con i pesi di TBOI.RESOURCE_CATEGORY_WEIGHTS
--   2. dentro la categoria si sceglie il tipo con i pesi (weight) di TBOI.END_OF_ROUND_REWARDS
TBOI.RESOURCES_TYPE = {
    heart = {
        'red_heart', 'half_red_heart', 'double_red_heart', 'soul_heart', 'half_soul_heart', 'black_heart',
        'half_black_heart', 'eternal_heart', 'golden_heart', 'bone_heart', 'rotted_heart'
    },
    bomb = {
        'bomb', 'double_bomb', 'golden_bomb', 'mega_bomb'
    },
    key = {
        'key', 'key_ring', 'golden_key', 'charged_key'
    },
    battery = {
        'lil_battery', 'micro_battery', 'mega_battery', 'golden_battery'
    },
    coin = {
        'dollar', 'nickel', 'lucky_penny', 'golden_penny', 'dime', 'double_penny'
        },
    card = {
        'tarot_card', 'playing_card', 'rune', 'special_card'
    },
    pill = {
        'pill', 'horse_pill', 'golden_pill'
    }
}
-- Peso di ogni categoria. Cuori, bombe, monete e chiavi hanno la stessa probabilità;
-- pillole, carte e batterie ciascuna 1/6 di una di quelle. 'nothing' è il tiro a vuoto.
TBOI.RESOURCE_CATEGORY_WEIGHTS = {
    nothing = 1,
    heart = 6, bomb = 6, coin = 6, key = 6,
    pill = 1, card = 1, battery = 1,
}

-- Carte speciali (chiavi senza prefisso dei consumabili c_tboi_...): non ancora create
TBOI.SPECIAL_CARDS = {
    'suicide_king','chaos_card','holy_card','credit_card','rules_card','a_card_against_humanity',
    '?_card','get_out_of_jail_free_card','emergency_contact','dice_shard','huge_growth','ancient_recall',
    'era_walk',"cracked_key",'wild_card'
    }
-- Peso di ogni tipo DENTRO la sua categoria (vedi TBOI.RESOURCES_TYPE) e valore per la Bag of Crafting.
-- Il peso di 'nothing' qui non conta: la sua probabilità è in TBOI.RESOURCE_CATEGORY_WEIGHTS.
TBOI.END_OF_ROUND_REWARDS = {
    {type = 'nothing',          weight = 30, value = 0},
    {type = 'poop',             weight = 0, value = 0},
    {type = 'dollar',           weight = 91.72, value = 1},
    {type = 'double_penny',     weight = 0, value = 1},
    {type = 'key',              weight = 96.08, value = 2},
    {type = 'key_ring',         weight = 1, value = 2},
    {type = 'bomb',             weight = 74.84, value = 2},
    {type = 'double_bomb',      weight = 12.47, value = 2},
    {type = 'red_heart',        weight = 39.98, value = 1},
    {type = 'half_red_heart',   weight = 39.99, value = 1},
    {type = 'double_red_heart', weight = 5, value = 1},
    {type = 'rotted_heart',     weight = 1.71, value = 1},
    {type = 'playing_card',     weight = 17, value = 2},
    {type = 'tarot_card',       weight = 87, value = 2},
    {type = 'special_card',     weight = 1, value = 2},
    {type = 'pill',             weight = 94, value = 2},
    {type = 'horse_pill',       weight = 1, value = 2},
    {type = 'micro_battery',    weight = 65.45, value = 2},
    {type = 'cracked_key',      weight = 0, value = 2},
    {type = 'nickel',           weight = 4.92, value = 3},
    {type = 'soul_heart',       weight = 6.73, value = 4},
    {type = 'half_soul_heart',  weight = 2.24, value = 4},
    {type = 'rune',             weight = 5, value = 4},
    {type = 'lil_battery',      weight = 32.72, value = 4},
    {type = 'dice_shard',       weight = 0, value = 4},
    {type = 'black_heart',      weight = 0.5, value = 5},
    {type = 'half_black_heart', weight = 0, value = 5},
    {type = 'eternal_heart',    weight = 1.8, value = 5},
    {type = 'bone_heart',       weight = 0.47, value = 5},
    {type = 'charged_key',      weight = 1.96, value = 5},
    {type = 'dime',             weight = 1, value = 5},
    {type = 'golden_heart',     weight = 0.63, value = 5},
    {type = 'golden_key',       weight = 1.97, value = 7},
    {type = 'golden_bomb',      weight = 0.89, value = 7},
    {type = 'golden_penny',     weight = 0.5, value = 7},
    {type = 'golden_pill',      weight = 5, value = 7},
    {type = 'golden_battery',   weight = 0.83, value = 7},
    {type = 'lucky_penny',      weight = 0.93, value = 8},
    {type = 'mega_battery',     weight = 1, value = 8},
    {type = 'mega_bomb',        weight = 0, value = 10},
}
TBOI.BAG_OF_CRAFTING = {}
TBOI.BAG_OF_CRAFTING.CRAFTING_QUALITY = {
    {min_quality = 0, max_quality = 1, min_amount = 0, max_amount = 8},
    {min_quality = 0, max_quality = 2, min_amount = 9, max_amount = 14},
    {min_quality = 1, max_quality = 2, min_amount = 15, max_amount = 18},
    {min_quality = 2, max_quality = 3, min_amount = 19, max_amount = 22},
    {min_quality = 2, max_quality = 4, min_amount = 23, max_amount = 26},
    {min_quality = 3, max_quality = 4, min_amount = 27, max_amount = 34},
    {min_quality = 4, max_quality = 4, min_amount = 35, max_amount = 80}
}
-- Qualità (0-4) del joker creato -> rarità del joker (1 comune, 2 non comune, 3 raro, 4 leggendario)
TBOI.BAG_OF_CRAFTING.QUALITY_TO_RARITY = {
    [0] = 1,
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
}
TBOI.BAG_OF_CRAFTING.SPECIAL_CRAFTING_QUALITY = {
    {min_quality = 0, max_quality = 1, min_amount = 0, max_amount = 13},
    {min_quality = 0, max_quality = 2, min_amount = 14, max_amount = 19},
    {min_quality = 1, max_quality = 2, min_amount = 20, max_amount = 23},
    {min_quality = 2, max_quality = 3, min_amount = 24, max_amount = 27},
    {min_quality = 2, max_quality = 4, min_amount = 28, max_amount = 31},
    {min_quality = 3, max_quality = 4, min_amount = 32, max_amount = 39},
    {min_quality = 4, max_quality = 4, min_amount = 40, max_amount = 80}
}
TBOI.BAG_OF_CRAFTING.FIXED_RECIPES = {
    {item = 'the_poop', materials = {{pickup = 'poop',amount = 8}}},
    {item = 'mr_boom', materials = {{pickup = 'bomb',amount = 8}}},
    {item = 'red_key', materials = {{pickup = 'cracked_key',amount = 8}}},
    {item = 'yum_heart', materials = {{pickup = 'red_heart',amount = 8}}},
    {item = 'yuck_heart', materials = {{pickup = 'rotted_heart',amount = 8}}},
    {item = 'phd', materials = {{pickup = 'pill',amount = 8}}},
    {item = 'false_phd', materials = {
        {pickup = 'pill',amount = 7},
        {pickup = 'black_heart', amount = 1}}},
    {item = 'deck_of_cards', materials = {{pickup = 'card',amount = 8}}},
    {item = 'brimstone', materials = {{pickup = 'black_heart',amount = 8}}},
    {item = 'dads_key', materials = {
        {pickup = 'key',amount = 6},
        {pickup = 'golden_key', amount = 2}}},
    {item = 'sacred_heart', materials = {{pickup = 'eternal_heart',amount = 8}}},
    {item = 'godhead', materials = {
        {pickup = 'eternal_heart',amount = 5},
        {pickup = 'golden_heart',amount=1},
        {pickup = 'red_heart',amount=1},
        {pickup = 'soul_heart',amount=1}}},
    {item = 'latch_key', materials = {{pickup = 'key',amount = 8}}},
    {item = 'mama_mega', materials = {{pickup = 'mega_bomb',amount = 8}}},
    {item = 'mama_mega', materials = {
        {pickup = 'bomb',amount = 6},
        {pickup = 'golden_bomb', amount = 2}}},
    {item = 'soul_locket', materials = {{pickup = 'soul_heart',amount = 8}}},
    {item = 'portable_slot', materials = {{pickup = 'dollar',amount = 8}}},
    {item = 'd_infinity', materials = {{pickup = 'dice_shard',amount = 8}}},
    {item = 'death_certificate', materials = {{pickup = 'bone_heart',amount = 8}}}
}
TBOI.BAG_OF_CRAFTING.INFLUENCES = {
    {type = 'rune', pool = 'planetarium'},
    {type = 'black_heart', pool = 'devil'},
    {type = 'eternal_heart', pool = 'angel'},
    {type = 'cracked_key', pool = 'red_chest'},
    {type = 'golden_heart', pool = 'chest'},
    {type = 'rotten_heart', pool = 'curse'},
    {type = 'bone_heart', pool = 'secret_room'}
}

-- Icona (carattere del font) e colore di ogni risorsa, usati nella valutazione del round.
-- font: 'm6x11plus' è il font di Balatro (per '$'), altrimenti il font della mod (tboi_tboim6x11)
local ISAAC_FONT = 'tboi_tboim6x11'
local BROWN  = HEX('8B5A2B')
local AZURE  = HEX('7FC8F8')
local PALE_Y = HEX('F3E9A2')
TBOI.RESOURCE_ICONS = {
    dollar           = { icon = '$', colour = G.C.MONEY,              font = 'm6x11plus' },
    double_penny     = { icon = '$', colour = G.C.MONEY,              font = 'm6x11plus' },
    nickel           = { icon = '$', colour = G.C.GREY,               font = 'm6x11plus' },
    dime             = { icon = '$', colour = G.C.WHITE,              font = 'm6x11plus' },
    golden_penny     = { icon = '$', colour = G.C.YELLOW,             font = 'm6x11plus' },
    lucky_penny      = { icon = '$', colour = G.C.GREEN,              font = 'm6x11plus' },
    key              = { icon = 'A', colour = lighten(G.C.GREY, 0.2), font = ISAAC_FONT },
    key_ring         = { icon = 'A', colour = lighten(G.C.GREY, 0.2), font = ISAAC_FONT },
    charged_key      = { icon = 'A', colour = PALE_Y,                 font = ISAAC_FONT },
    golden_key       = { icon = 'A', colour = G.C.GOLD,               font = ISAAC_FONT },
    cracked_key      = { icon = 'A', colour = G.C.RED,                font = ISAAC_FONT },
    bomb             = { icon = 'B', colour = G.C.GREY,               font = ISAAC_FONT },
    double_bomb      = { icon = 'B', colour = G.C.GREY,               font = ISAAC_FONT },
    golden_bomb      = { icon = 'B', colour = G.C.GOLD,               font = ISAAC_FONT },
    mega_bomb        = { icon = 'B', colour = G.C.RED,                font = ISAAC_FONT },
    red_heart        = { icon = 'H', colour = G.C.RED,                font = ISAAC_FONT },
    half_red_heart   = { icon = 'h', colour = G.C.RED,                font = ISAAC_FONT },
    double_red_heart = { icon = 'H', colour = G.C.RED,                font = ISAAC_FONT },
    rotted_heart     = { icon = 'H', colour = G.C.GREEN,              font = ISAAC_FONT },
    soul_heart       = { icon = 'H', colour = AZURE,                  font = ISAAC_FONT },
    half_soul_heart  = { icon = 'h', colour = AZURE,                  font = ISAAC_FONT },
    black_heart      = { icon = 'H', colour = G.C.GREY,               font = ISAAC_FONT },
    half_black_heart = { icon = 'h', colour = G.C.GREY,               font = ISAAC_FONT },
    eternal_heart    = { icon = 'h', colour = G.C.WHITE,              font = ISAAC_FONT },
    bone_heart       = { icon = 'h', colour = lighten(G.C.GREY, 0.4), font = ISAAC_FONT },
    golden_heart     = { icon = 'H', colour = G.C.GOLD,               font = ISAAC_FONT },
    tarot_card       = { icon = 'c', colour = BROWN,                  font = ISAAC_FONT },
    playing_card     = { icon = 'c', colour = G.C.RED,                font = ISAAC_FONT },
    rune             = { icon = 'c', colour = G.C.GREY,               font = ISAAC_FONT },
    special_card     = { icon = 'c', colour = G.C.PURPLE,             font = ISAAC_FONT },
    micro_battery    = { icon = 'b', colour = G.C.GREY,               font = ISAAC_FONT },
    lil_battery      = { icon = 'b', colour = G.C.YELLOW,             font = ISAAC_FONT },
    mega_battery     = { icon = 'b', colour = lighten(G.C.GREY, 0.4), font = ISAAC_FONT },
    golden_battery   = { icon = 'b', colour = G.C.GOLD,               font = ISAAC_FONT },
    -- Risorse non ancora implementate: icona provvisoria
    pill             = { icon = 'P', colour = G.C.RED,                font = ISAAC_FONT },
    horse_pill       = { icon = 'P', colour = G.C.GOLD,                font = ISAAC_FONT },
    golden_pill      = { icon = 'P', colour = G.C.RED,                font = ISAAC_FONT },
    dice_shard       = { icon = 'd', colour = G.C.WHITE,              font = ISAAC_FONT },
    poop             = { icon = 'o', colour = BROWN,                  font = ISAAC_FONT },
}

-- Bag of Crafting: quante risorse contiene prima di creare un joker
TBOI.BAG_OF_CRAFTING.CAPACITY = 8
TBOI.BAG_OF_CRAFTING.KEY = 'j_tboi_bag_of_crafting'
-- Posizione nell'atlas dello sprite della borsa chiusa (aperta: il pos del joker)
TBOI.BAG_OF_CRAFTING.CLOSED_POS = { x = 2, y = 1 }
-- Risorse che entrano nella borsa come altri materiali (ogni materiale occupa un posto)
TBOI.BAG_OF_CRAFTING.CONVERSIONS = {
    double_bomb      = { 'bomb', 'bomb' },
    double_penny     = { 'dollar', 'dollar' },
    key_ring         = { 'key', 'key' },
    double_red_heart = { 'red_heart', 'red_heart' },
    half_red_heart   = { 'red_heart' },
    half_soul_heart  = { 'soul_heart' },
    half_black_heart = { 'black_heart' },
}

-- Mazzo the_hoarder: ogni joker distrutto dà un numero casuale di risorse tra min e max (inclusi)
TBOI.HOARDER_REWARDS = {
    min = 3, -- risorse minime per joker distrutto
    max = 7, -- risorse massime per joker distrutto
}

-- Mazzo the_hoarder: joker le cui COPIE non vengono trasformate in risorse.
-- I joker elencati vengono trasformati normalmente quando li ottieni; i joker che creano
-- copiando (es. Invisible Joker quando viene venduto) invece restano.
TBOI.HOARDER_COPY_SOURCES = {
    j_invisible = true,
}
