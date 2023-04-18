print([[

Created by HonkyRot
Created on 1/15/2023
Converted from Python to Lua at the best of my abilities

Welcome to UNO!
This is a single-player game.
You will be playing against the computer with 3 cpus.

The goal of the game is to get rid of all your cards.
You can do this by matching the color or number of the card on top of the discard pile.
You can also play a wild card to change the color of the discard pile.
You can also play a wild draw four card to change the color of the discard pile and make the next player draw four cards.

This version will not have the callable "uno" feature.
Will not have any stacking/challenging and follows house rules.
]])

local show_debug = true -- set to true to show debug messages
if show_debug then
    print("[DEBUG] Debug mode is on")
end

UNO_Game = {}

--settings
local settings_cards_to_draw_out = 7

local deck_colors = {"red", "blue", "yellow", "green"}
local standard_values = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
local action_values = {"skip", "reverse", "draw2"}
local wild_values = {"wild", "wild4"}

function math_clamp(num, min, max)
    return math.min(math.max(num, min), max)
end

function yes_no_response(message) --force a y/n response
    while true do
        print(message)
        io.write()
        local input = io.read()
        input = string.lower(input)
        if input == "y" or input == "yes" then
            return true
        elseif input == "n" or input == "no" then
            return false
        else
            print("--Invalid input--")
        end
    end
end

function title_case(str) --stolen
    return string.gsub(" "..str, "%W%l", string.upper):sub(2)
end

function UNO_Game:Start_Game_init() --Set up the game. Also the basis of the metatable and the object
    local game = {}
    setmetatable(game, self)
    self.__index = self
    self.games_played = 0
    self.current_turn = 0

    self.clockwise = true
    self.last_played_card = nil
    self.last_played_color = nil

    self.current_player_ID = 1
    self.dealer = {["hand"] = {}, ["name"] = "Dealer", ["ID"] = 0}

    self.player1 = {["hand"] = {}, ["name"] = "Player", ["ID"] = 1}
    self.cpu2 = {["hand"] = {}, ["name"] = "CPU 1", ["ID"] = 2}
    self.cpu3 = {["hand"] = {}, ["name"] = "CPU 2", ["ID"] = 3}
    self.cpu4 = {["hand"] = {}, ["name"] = "CPU 3", ["ID"] = 4}

    self.deck = {}
    self.discard_pile = {}

    self.cards_drawn = 0
    self.cards_per_player = settings_cards_to_draw_out

    return game
end

function UNO_Game:Reset_Deck()  -- Resets the game and increments games_played
    self.player1.hand = {}
    self.cpu2.hand = {}
    self.cpu3.hand = {}
    self.cpu4.hand = {}
    self.deck = {}
    self.discard_pile = {}
    self.clockwise = true
    self.games_played = self.games_played + 1
end

function UNO_Game:Create_Deck() --creates a deck
    for _, color in ipairs(deck_colors) do
        for _, value in ipairs(standard_values) do
            table.insert(self.deck, {color, value})
            if value ~= "0" then --One set of zeros
                table.insert(self.deck, {color, value})
            end
        end
        for _, value in ipairs(action_values) do
            table.insert(self.deck, {color, value})
            table.insert(self.deck, {color, value})
        end
    end
    for _, value in ipairs(wild_values) do
        table.insert(self.deck, {value})
        table.insert(self.deck, {value})
        table.insert(self.deck, {value})
        table.insert(self.deck, {value})
    end
end

function UNO_Game:Shuffle_Deck()
    for i = 1, #self.deck do
        local e = math.random(1, #self.deck)
        self.deck[i], self.deck[e] = self.deck[e], self.deck[i]
    end
end

function UNO_Game:Draw_Card(player)
    if #self.deck > 0 then
        local card = table.remove(self.deck, 1)
        self.cards_drawn = self.cards_drawn + 1
        if player then
            table.insert(player.hand, card)
        else
            error("Invalid player")
        end
        return card
    else
        self:Create_Deck()
        local card = table.remove(self.deck, 1)
        self.cards_drawn = self.cards_drawn + 1
        if player then
            table.insert(player.hand, card)
        else
            error("Invalid player")
        end
        return card
    end
end

function UNO_Game:Pass_Out_Cards() --Passes out cards
    for _ = 1, self.cards_per_player do
        self:Draw_Card(self.player1)
        self:Draw_Card(self.cpu2)
        self:Draw_Card(self.cpu3)
        self:Draw_Card(self.cpu4)
    end
end

function UNO_Game:Print_Out_Cards_In_Deck()
    print(#self.deck.." cards remaining in deck")
    print(#self.discard_pile.." cards in discard pile")
end

function UNO_Game:Print_Players_Deck() --prints out player's hand
    print("Your hand: (Cards Left: "..#self.player1.hand..")")
    for i, card in ipairs(self.player1.hand) do
        local can_play = self:Check_If_Card_Can_Be_Played(card)
        local card_str = tostring(card[1])
        if not card[2] then
            card[2] = "card"
        end
        if card[2] == "draw2" then
            card[2] = "draw 2"
        end
        if card[1] == "wild4" then
            card[1] = "wild"
            card[2] = "card"
        end
        local card_str2 = tostring(card[2])
        if can_play then
            print("◆ ["..i.."] "..title_case(card_str).." "..card_str2)
        else
            print("◇ ["..i.."] "..title_case(card_str).." "..card_str2)
        end
    end
end

function UNO_Game:Four_Loopback(number, increment) --clamps a number between 1 and 4
    if self.clockwise then
        if number + increment > 4 then
            return 1
        elseif number + increment < 1 then
            return 4
        else
            return number + increment
        end
    else
        if number - increment > 4 then
            return 1
        elseif number - increment < 1 then
            return 4
        else
            return number - increment
        end
    end
end

function UNO_Game:Number_ID_To_Player(num) --returns a player
    if num == 1 then
        return self.player1
    elseif num == 2 then
        return self.cpu2
    elseif num == 3 then
        return self.cpu3
    elseif num == 4 then
        return self.cpu4
    else
        error("Invalid player ID")
    end
end

function UNO_Game:Check_Winner() --checks all player's hand if its empty, if it is that player wins!
    if #self.player1.hand == 0 then
        print("Player 1 wins!")
        return true
    elseif #self.cpu2.hand == 0 then
        print("CPU 2 wins!")
        return true
    elseif #self.cpu3.hand == 0 then
        print("CPU 3 wins!")
        return true
    elseif #self.cpu4.hand == 0 then
        print("CPU 4 wins!")
        return true
    else
        return false
    end
end

function UNO_Game:Next_Turn() --next player
    if self.clockwise then
        self.current_turn = self.current_turn + 1
    else
        self.current_turn = self.current_turn - 1
    end
    self.current_player_ID = self:Four_Loopback(self.current_player_ID, 1)
end

function UNO_Game:Discard_Played_Card(player, card, card_pos) --adds a card to discard pile
    table.insert(self.discard_pile, card)
    table.remove(player.hand, card_pos)
    if show_debug then
        print("[DEBUG] Discarded "..tostring(self.last_played_card[1]).." "..tostring(self.last_played_card[2]))
    end
end

function UNO_Game:Refill_Deck() --refills deck from discard pile
    for i = 1, #self.discard_pile do
        table.insert(self.deck, self.discard_pile[i])
    end
    self.discard_pile = {}
end

function UNO_Game:Draw_Cards(player, amount)  --draws x amount of cards to a player
    for _ = 1, amount do
        self:Draw_Card(player)
    end
end

function UNO_Game:Check_If_Card_Can_Be_Played(card) --checks if a card can be played
    if self.last_played_card == nil then
        error("fuck, missing the last played card")
    end
    if card[1] == self.last_played_color or card[2] == self.last_played_card[2] or card[1] == "wild" or card[1] == "wild4" then
        return true
    else
        return false
    end
end

function UNO_Game:Wild_Select_Color()
    local color = ""
    while color ~= "red" and color ~= "blue" and color ~= "green" and color ~= "yellow" do
        print("Please select a color: red, blue, green, or yellow")
        io.write("> ")
        color = io.read()
        color = string.lower(color)
    end
    return color
end

function UNO_Game:Play_Card(player, card, card_pos) --plays a card from hand
    if self:Check_If_Card_Can_Be_Played(card) then
        if not player then
            error("Invalid player")
        end
        self.last_played_card = card
        self.last_played_color = card[1]
        self:Discard_Played_Card(player, card, card_pos)
        if card[2] == "skip" then
            if show_debug then
                print("[DEBUG] ACTION: SKIP")
            end
            self:Action_Skip()
        elseif card[2] == "reverse" then
            if show_debug then
                print("[DEBUG] ACTION: REVERSE")
            end
            self:Action_Reverse()
        elseif card[2] == "draw2" or card[2] == "draw 2" then
            if show_debug then
                print("[DEBUG] ACTION: DRAW 2")
            end
            self:Action_Draw2()
        elseif card[1] == "wild4" and player.name == "Player" then
            if show_debug then
                print("[DEBUG] ACTION: WILD 4")
            end
            self:Action_Wild4(false)
        elseif card[1] == "wild4" and player.name ~= "Player" then
            if show_debug then
                print("[DEBUG] ACTION: (DEALER) WILD 4")
            end
            self:Action_Wild4(true)
        elseif card[1] == "wild" and player.name == "Player" then
            if show_debug then
                print("[DEBUG] ACTION: WILD")
            end
            self:Action_Wild(false)
        elseif card[1] == "wild" and player.name ~= "Player" then
            if show_debug then
                print("[DEBUG] ACTION: (DEALER) WILD")
            end
            self:Action_Wild(true)
        end
        return true
    else
        return false
    end
end

function UNO_Game:Print_Last_Played_Card()
    local str2 = tostring(self.last_played_card[2])
    if str2 == "nil" then
        str2 = "wild / card"
    end
    print("Last card played: "..self.last_played_color.." "..str2)
end

function UNO_Game:Action_Reverse() --reverses the direction of play
    print("Going backwards")
    self.clockwise = not self.clockwise
end

function UNO_Game:Action_Skip() --skips the next player
    local player = self:Number_ID_To_Player(self:Four_Loopback(self.current_player_ID, 1))
    print("Skipping "..player.name)
    self.current_player_ID = self:Four_Loopback(self.current_player_ID, 1) --increment by 1 for next_turn() to increment by 1 again
    self:Next_Turn()
end

function UNO_Game:Action_Draw2() --draws 2 cards for next player
    local player = self:Number_ID_To_Player(self:Four_Loopback(self.current_player_ID, 1))
    print(player.name.." draws 2 cards and skips their turn")
    self:Draw_Cards(player, 2)
    self:Action_Skip(player)
end

function UNO_Game:Action_Wild(random) --changes the color of the next card played
    self.last_played_color = "wild"
    if random == true then
        self.last_played_color = ({"red", "blue", "green", "yellow"})[math.random(1, 4)]
    else
        self.last_played_color = self:Wild_Select_Color()
    end
end

function UNO_Game:Action_Wild4(random) --changes the color of the next card played and draws 4 cards for next player
    local player = self:Number_ID_To_Player(self:Four_Loopback(self.current_player_ID, 1))
    self:Draw_Cards(player, 4)
    self:Action_Skip(player)
    self.last_played_color = "wild4"
    print(player.name.." draws 4 cards and skips their turn")
    if random == true then
        self.last_played_color = ({"red", "blue", "green", "yellow"})[math.random(1, 4)]
    else
        self.last_played_color = self:Wild_Select_Color()
    end
end

function UNO_Game:Draw_Dealer_First_Card() --ran only once per game
    print("Dealer is passing out cards...")
    while true do
        local card = self:Draw_Card(self.dealer)
        if card[2] == "draw2" or card[2] == "draw 2" or card[2] == "skip" or card[2] == "reverse" then --ignore all action cards
            self.last_played_card = card
            self.last_played_color = card[1]
            self:Discard_Played_Card(self.dealer, card, 1)
            self:Refill_Deck()
        else
            self.last_played_card = card
            self.last_played_color = card[1]
            self:Play_Card(self.dealer, card, 1)
            print("Dealer drew "..card[1].." "..tostring(card[2]))
            break
        end
    end
end

function UNO_Game:Player_Selection() --get player's selection
    while true do
        local selection
        print("Please select a card, type [0] to draw a card.")
        io.write()
        local input = io.read()
        input = tonumber(input)
        if input then
            if input ~= 0 then
                selection = math_clamp(input, 1, #self.player1.hand)
                local find_card = self.player1.hand[selection]
                print("Playing "..find_card[1].." "..find_card[2])
                local checks_1 = self:Check_If_Card_Can_Be_Played(find_card)
                if checks_1 then
                    return find_card, selection
                else
                    print("You can't play that card!")
                end
            else
                print("Drawing card...")
                self:Draw_Card(self.player1)
                local str3 = tostring(self.player1.hand[#self.player1.hand][2])
                if str3 == "nil" then
                    str3 = "card"
                end
                print("Drew a "..self.player1.hand[#self.player1.hand][1].." "..str3)
                return "draw", 0
            end
        else
            print("SELECTION INVALID, PLEASE TYPE A NUMBER!")
        end
    end
end

--AI decisions
--If AI does not have card compatible in hand, draw ONCE and move to next player.
--If AI does have a compatible card. Play the card.
--    Action Card Order >
--        first in list goes first!
--    Highest Priority Cards >
--        If they don't have the color while having an +4, play +4.
--        Action cards first if color match or action match.
--    High Priority Cards >
--        If +2 card in hand matches color or played +2 card, play it.
--    Medium Priority Cards >
--        If any card in hand does not match, play wild card.
--    Low Priority Cards >
--        Any number face card.
--        Any color matching card.
--    Lowest Priority >
--        Draw card


function UNO_Game:AI_Selection(ai_id)  --ai picks the card to play
    local ai_deck = {} --put it in a separate controllable table/deck
    for _, cards in ipairs(ai_id.hand) do
        _check = self:Check_If_Card_Can_Be_Played(cards)
        table.insert(ai_deck, {cards, _check})
    end
    self:Print_Last_Played_Card()
    if show_debug then
        print("[DEBUG] AI's cards: ")
        for _, cards in ipairs(ai_deck) do
            if cards[2] then
                print("◆ [".._.."] "..(tostring(cards[1][1])).." "..tostring(cards[1][2]))
            else
                print("◇ [".._.."] "..(tostring(cards[1][1])).." "..tostring(cards[1][2]))
            end
        end
    end
--    local selected_card = nil
    local has_color_matching_card = {["exist"] = false, ["card"] = nil, ["pos"] = nil}
    local has_number_matching_card = {["exist"] = false, ["card"] = nil, ["pos"] = nil}
    local has_wild_card = {["exist"] = false, ["card"] = nil, ["pos"] = nil}
    local has_wild4_card = {["exist"] = false, ["card"] = nil, ["pos"] = nil}
    local has_draw2_card = {["exist"] = false, ["card"] = nil, ["pos"] = nil}
    local has_skip_card = {["exist"] = false, ["card"] = nil, ["pos"] = nil}
    local has_reverse_card = {["exist"] = false, ["card"] = nil, ["pos"] = nil}
    for _, card in ipairs(ai_deck) do -- checks for any matching color
        if card[1][1] == self.last_played_color then
            has_color_matching_card.exist = true
            has_color_matching_card.card = card
            has_color_matching_card.pos = _
            break
        end
    end
    for _, card in ipairs(ai_deck) do -- checks for any matching number
        if card[1][2] == self.last_played_card[2] then
            has_number_matching_card.exist = true
            has_number_matching_card.card = card
            has_number_matching_card.pos = _
            break
        end
    end
    for _, card in ipairs(ai_deck) do -- checks for any wild card
        if card[1][1] == "wild" then
            has_wild_card.exist = true
            has_wild_card.card = card
            has_wild_card.pos = _
            break
        end
    end
    for _, card in ipairs(ai_deck) do -- checks for any wild4 card
        if card[1][1] == "wild4" then
            has_wild4_card.exist = true
            has_wild4_card.card = card
            has_wild4_card.pos = _
            break
        end
    end
    for _, card in ipairs(ai_deck) do -- checks for any draw2 card
        if card[1][2] == "draw2" then
            has_draw2_card.exist = true
            has_draw2_card.card = card
            has_draw2_card.pos = _
            break
        end
    end
    for _, card in ipairs(ai_deck) do -- checks for any skip card
        if card[1][2] == "skip" then
            has_skip_card.exist = true
            has_skip_card.card = card
            has_skip_card.pos = _
            break
        end
    end
    for _, card in ipairs(ai_deck) do -- checks for any reverse card
        if card[1][2] == "reverse" then
            has_reverse_card.exist = true
            has_reverse_card.card = card
            has_reverse_card.pos = _
            break
        end
    end
    if not has_color_matching_card.exist then -- does not have any matching colors at all!
        if show_debug then
            print("[DEBUG] 1 - No matching color.")
        end
        if has_number_matching_card.exist and not has_wild4_card.exist then
            if show_debug then
                print("[DEBUG] 1.1 - Has matching number.")
            end
            return has_number_matching_card.card, has_number_matching_card.pos
        end
        if has_wild4_card.exist then
            if show_debug then
                print("[DEBUG] 2 - Has wild4 card.")
            end
            return has_wild4_card.card, has_wild4_card.pos
        else
            if show_debug then
                print("[DEBUG] 2.1 - No wild4 card, Draws instead.")
            end
            return "draw", nil
        end
        if has_reverse_card and self.last_played_card[2] == "reverse" then
            if show_debug then
                print("[DEBUG] 2.2 - No wild4 card, Has playable reverse card.")
            end
            return has_reverse_card.card, has_reverse_card.pos
        end
    else
        if show_debug then
            print("[DEBUG] 3 - Has matching color.")
        end
        if has_skip_card.exist then
            if show_debug then
                print("[DEBUG] 4 - Has skip card.")
            end
            if has_skip_card.card[1] == self.last_played_color or has_skip_card[2] == self.last_played_card[2] then
                if show_debug then
                    print("[DEBUG] 5 - Skip card matches.")
                end
                return has_skip_card.card, has_skip_card.pos
            end
        end
        if has_reverse_card.exist then
            if show_debug then
                print("[DEBUG] 6 - Has reverse card.")
            end
            if has_reverse_card.card[1] == self.last_played_color or has_reverse_card[2] == self.last_played_card[2] then
                if show_debug then
                    print("[DEBUG] 7 - Reverse card matches.")
                end
                return has_reverse_card.card, has_reverse_card.pos
            end
        end
        if has_draw2_card.exist then
            if show_debug then
                print("[DEBUG] 8 - Has draw2 card.")
            end
            if has_draw2_card.card[1] == self.last_played_color or has_draw2_card[2] == self.last_played_card[2] then
                if show_debug then
                    print("[DEBUG] 9 - Draw2 card matches.")
                end
                return has_draw2_card.card, has_draw2_card.pos
            end
        end
        if has_wild_card.exist then
            if show_debug then
                print("[DEBUG] 10 - Has wild card.")
            end
            return has_wild_card.card, has_wild_card.pos
        end
        if has_color_matching_card.exist then --even though this is already checked, it has to play before matching numbers
            print("[DEBUG] 11 - Has matching color.")
            return has_color_matching_card.card, has_color_matching_card.pos
        end
        if has_number_matching_card.exist then --checks for matching numbers
            print("[DEBUG] 12 - Has matching number.")
            return has_number_matching_card.card, has_number_matching_card.pos
        end
    end
    if show_debug then
        print("[DEBUG] 0 - Draws.")
    end
    return "draw", nil
end

function UNO_Game:Wait_For_Player()
    io.write()
    print()
    print("Press [any] key to continue")
    io.read()
end


--gameplay part

local play_game_active = yes_no_response("Would you like to play a game of UNO? (y/n)")
while play_game_active do
    print("active")
    local game_active = true
    local game_count = 0
    while game_active do
        game_count = game_count + 1
        local_uno_game = UNO_Game:Start_Game_init()
        local_uno_game:Create_Deck()
        local_uno_game:Shuffle_Deck()
        local_uno_game:Pass_Out_Cards()
        local_uno_game:Draw_Dealer_First_Card()
        local turn_over = false
        while not turn_over do
            local cur_turn_math = math.abs((local_uno_game.current_turn) % 4)
            local check_win = local_uno_game:Check_Winner()
            if check_win then
                turn_over = true
                break
            end
            if cur_turn_math == 0 then
                print("It is your turn!")
                print("Please pick a card to play!\n")
                local_uno_game:Print_Last_Played_Card()
                print("\nRemaining cards in Deck: "..#local_uno_game.deck)
                print("Cards in discard pile: "..#local_uno_game.discard_pile)
                local_uno_game:Print_Players_Deck()
                local card, position = local_uno_game:Player_Selection()
                if card ~= "draw" then
                    local_uno_game:Play_Card(local_uno_game.player1, card, position)
                end
            elseif cur_turn_math > 0 then --AN AI turn
                local assigned_ai_turn
                if cur_turn_math == 1 then
                    assigned_ai_turn = local_uno_game.cpu2
                elseif cur_turn_math == 2 then
                    assigned_ai_turn = local_uno_game.cpu3
                elseif cur_turn_math == 3 then
                    assigned_ai_turn = local_uno_game.cpu4
                else
                    print("ERROR: AI TURN MATH ERROR")
                end
                print("It is "..assigned_ai_turn.name.."'s turn!")
                local grabbed_card, position = local_uno_game:AI_Selection(assigned_ai_turn)
                if grabbed_card == "draw" or not grabbed_card then
                    print("\n"..assigned_ai_turn.name.." is drawing a card\n")
                    local_uno_game:Draw_Card(assigned_ai_turn)
                else
                    local actual_card = assigned_ai_turn.hand[position]
                    local card_pos_2_string
                    if grabbed_card[1][2] == nil then
                        card_pos_2_string = "card"
                    else
                        card_pos_2_string = grabbed_card[1][2]
                    end
                    print("\n"..assigned_ai_turn.name.." played "..title_case(tostring(grabbed_card[1][1])).." "..card_pos_2_string.."\n")
                    local_uno_game:Play_Card(assigned_ai_turn, actual_card, position)
                end
            end
            local_uno_game:Wait_For_Player()
            local_uno_game:Next_Turn()
            print("Next player's turn")
        end
        local play_again = yes_no_response("Play again? (y/n)")
        io.write()
        if not play_again then
            game_active = false
        end
    end
    break
end
print("Good Bye!")
