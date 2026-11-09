-- Costanti della barra della vita. Il codice che le usa è in src/functions/healt.lua

TBOI.HEART_CONFIG = {
    max_slots       = 18,
    icons_per_row   = 6,
    icon_w = 0.35, icon_h = 0.35, icon_scale = 1.35,
    atlas_key = 'tboi_hearts',
    overtime_damage = 1 -- Danno (in mezzi cuori) per ogni mano giocata con 1 o 0 mani rimaste
}

TBOI.FRAMES = {
    empty        = {x=0, y=0},
    red_full     = {x=1, y=0},
    red_half     = {x=1, y=1},
    blue_full    = {x=2, y=0},
    blue_half    = {x=2, y=1},
    black_full   = {x=3, y=0},
    black_half   = {x=3, y=1},
    gold         = {x=4, y=0},
    eternal      = {x=4, y=1},
    bone         = {x=5, y=0},
    rotten       = {x=5, y=1}
}
