-- Registrazione ordinata di joker e mazzi.
-- I file di contenuto non chiamano direttamente SMODS.Joker / SMODS.Back ma TBOI.Joker / TBOI.Back,
-- che mettono da parte la definizione. Dopo aver caricato tutto il contenuto, main.lua chiama
-- TBOI.FUNCS.register_all(), che li registra nell'ordine scelto in:
--   - TBOI.JOKER_ORDER (src/content/jokers/jokers.lua)
--   - TBOI.DECK_ORDER  (src/content/decks/decks.lua)
-- L'ordine di registrazione è l'ordine nella collezione, nel selettore dei mazzi
-- e negli ID usati dallo Spindown Dice.

TBOI.PENDING = { Joker = {}, Back = {} }

function TBOI.Joker(def) table.insert(TBOI.PENDING.Joker, def) end
function TBOI.Back(def) table.insert(TBOI.PENDING.Back, def) end

--- Registra le definizioni in sospeso: prima quelle elencate in `order` (chiavi senza prefisso),
--- poi tutte le altre nell'ordine in cui i file sono stati caricati.
local function register_in_order(kind, order, constructor)
    local pending = TBOI.PENDING[kind]

    -- Le chiavi vanno lette PRIMA di registrare: il costruttore SMODS modifica la definizione
    -- (es. 'the_d_six' diventa 'j_tboi_the_d_six') e registrarla due volte è un errore
    local keys, by_key = {}, {}
    for _, def in ipairs(pending) do
        local key = def.key
        if by_key[key] then
            sendWarnMessage(('%s "%s" definito due volte, uso il primo'):format(kind, tostring(key)), 'TBOI')
        else
            by_key[key] = def
            keys[#keys + 1] = key
        end
    end

    local registered = {}
    local function register(key)
        if registered[key] then return end
        registered[key] = true
        constructor(by_key[key])
    end

    for _, key in ipairs(order or {}) do
        if by_key[key] then
            register(key)
        else
            sendWarnMessage(('%s "%s" è nella lista d\'ordine ma non esiste'):format(kind, key), 'TBOI')
        end
    end
    -- Quelli non elencati, nell'ordine di caricamento dei file
    for _, key in ipairs(keys) do
        register(key)
    end

    TBOI.PENDING[kind] = {}
end

function TBOI.FUNCS.register_all()
    register_in_order('Joker', TBOI.JOKER_ORDER, SMODS.Joker)
    register_in_order('Back', TBOI.DECK_ORDER, SMODS.Back)
end
