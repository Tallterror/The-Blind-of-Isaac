-- Costanti delle pagine del negozio e dei cicli delle carte

-- Pagina del negozio -> nome della sua CardArea in G (es. G.treasure_room)
TBOI.tab_area_globals = {
    treasure = 'treasure_room',
    planetarium = 'planetarium',
}

-- Figli della carta da conservare quando il ciclo cambia joker (prezzo e pulsanti del negozio)
TBOI.CYCLE_KEPT_CHILDREN = { 'price', 'buy_button', 'buy_and_use_button', 'use_button' }
