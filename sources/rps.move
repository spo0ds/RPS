module rps::rps{
    use std::string;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use std::vector;
    use sui::dynamic_object_field as ofield;
    use sui::coin::{Self, Coin, TreasuryCap};
    use std::hash;

    const ROCK: u8 = 0;
    const PAPER: u8 = 1;
    const SCISSORS: u8 = 2;
    const HashNotMatched: u8 = 3;
    const FRIENDONLY: u8 = 4;
    const ONEONONE: u8 = 5;

    const ENotStakedAmount: u64 = 6;
    const EZeroStakedNotAllowed : u64 = 7;
    const ENotFriend: u64 = 8; 
    const EFriendNotPresent: u64 = 9;
    const ENotChallenger: u64 = 10; 
    const EGameFinishedAlready: u64 = 11;
    const ENotCreator: u64 = 12;
    const ETokenNotPresent: u64 = 13;
    const ECoinNotWhiteListed:u64 =14;
    const EHashNotMatched:u64 = 15;
    const EChallengerSameAsCreator:u64 = 16;

    struct RPS has drop {}

    struct RPSGame<phantom T> has key,store{
        id: UID,
        creator:address,
        challenger:Option<address>,
        message:Option<string::String>,
        player_one_move: vector<u8>,
        player_two_move: Option<u8>,
        winner : Option<address>,
        stakes:u64,
        balance: Balance<T>,
        distributed: bool,
        type: u8,
    }

    struct GameList has key{
        id: UID,
        rps_game_count:  u64,
        // rps dynamically gets added
    }

    struct FriendList has key {
        id: UID,
        address: vector<address>,
    }

    struct WhiteListedTokens has key {
        id: UID,
        address: vector<ID>,
    }

    struct FriendCap has key{
        id: UID, 
    }

    struct RPSGameCap has key{
        id: UID, 
    }

    fun init(witness: RPS, ctx:&mut TxContext) {
        let id = object::new(ctx);
        transfer::share_object(GameList {
            id,
            rps_game_count: 0u64,
        });
        transfer::transfer(RPSGameCap{
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        let (treasury_cap, metadata) = coin::create_currency<RPS>(
            witness,
            9,
            b"RPS",
            b"",
            b"",
            option::none(),
            ctx,
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::share_object(WhiteListedTokens{
            id: object::new(ctx),
            address: vector::empty(),
        });
    }

    public entry fun mint(
        treasury_cap: &mut TreasuryCap<RPS>, 
        amount: u64, 
        recipient: address, 
        ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    public fun updateWhiteListToken(_cap:&RPSGameCap, whitelisted: &mut WhiteListedTokens, coin_id: vector<ID>) {
        vector::append(&mut whitelisted.address, coin_id); 
    }

    public fun removeWiteListedTokens(_cap: &RPSGameCap, whitelisted: &mut WhiteListedTokens, tokenAddress: ID) {
        let (found, index) = vector::index_of(&whitelisted.address, &tokenAddress);
        assert!(found, ETokenNotPresent);
        vector::remove(&mut whitelisted.address, index);
    }

    public entry fun createFriendlist(ctx:&mut TxContext){
         transfer::transfer(FriendCap{
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::share_object(FriendList{
            id: object::new(ctx),
            address: vector::empty(),
        });
    }

    public entry fun updateToMyFriendList(_cap:&FriendCap, friendlist: &mut FriendList, addresses: vector<address>) {
        vector::append(&mut friendlist.address, addresses); 
    }

    public entry fun removeFriend(_cap: &FriendCap, friendlist: &mut FriendList, friendAddress: address) {
        let (found, index) = vector::index_of(&friendlist.address, &friendAddress);
        assert!(found, EFriendNotPresent);
        vector::remove(&mut friendlist.address, index);
    }

    public entry fun createGame<T>(challenger:Option<address>,message:Option<string::String>, player_one_move: vector<u8>,stakes:u64, coin: Coin<T>, type: u8, gameList_object: &mut GameList, whitelisted: &WhiteListedTokens, ctx: &mut TxContext){
        assert!(stakes > 0, EZeroStakedNotAllowed);
        let coinAddress = object::id(&coin);
        assert!(vector::contains(&whitelisted.address, &coinAddress) == true, ECoinNotWhiteListed);
        assert!(coin::value(&coin) == stakes, ENotStakedAmount);
        if (challenger != option::none()){
            assert!(tx_context::sender(ctx) != *option::borrow(&challenger), EChallengerSameAsCreator);
        };
        let rsp = RPSGame{
            id : object::new(ctx),
            creator : tx_context::sender(ctx),
            challenger : challenger,
            message: message,
            player_one_move: player_one_move,
            player_two_move: option::none(),
            winner: option::none(),
            stakes: stakes,
            balance: coin::into_balance(coin),
            distributed: false,
            type: type,
        };
        let rsp_id = object::id(&rsp);
        ofield::add(&mut gameList_object.id, rsp_id, rsp);
        gameList_object.rps_game_count = gameList_object.rps_game_count + 1;
    }

    public entry fun play_game<T>(child_id: ID, parent: &mut GameList, player_move:u8, coin:Coin<T>, friendlist: & FriendList, whitelisted: &WhiteListedTokens, ctx: &mut TxContext){
         mutate_move(ofield::borrow_mut<ID, RPSGame<T>>(
            &mut parent.id,
            child_id,
        ), player_move, coin , friendlist, tx_context::sender(ctx), whitelisted); 
    }

    public entry fun select_winner<T>(_cap: &RPSGameCap,child_id: ID, salt:vector<u8> ,gameList_object: &mut GameList,ctx: &mut TxContext) {
        mutate_winner(
            ofield::borrow_mut<ID, RPSGame<T>>(&mut gameList_object.id, child_id),
            salt,
            ctx,
        );
    }

    entry public fun cancel_game<T>(parent: &mut GameList, child_id: ID, ctx: &mut TxContext) {
        let RPSGame<T> {
            id,
            creator,
            challenger: _,
            message: _,
            player_one_move: _,
            player_two_move: _,
            winner: _,
            stakes: _,
            balance,
            distributed,
            type:_,
        } = ofield::remove(&mut parent.id, child_id);
        assert!(creator == tx_context::sender(ctx), ENotCreator);
        assert!(distributed == false, EGameFinishedAlready);
        let coin = sui::coin::from_balance(balance, ctx);
        sui::transfer::public_transfer(coin, creator);
        object::delete(id);
    }

    fun mutate_move<T>(rps: &mut RPSGame<T>, player_move: u8, coin:Coin<T>, friendlist: & FriendList, challenger: address, whitelisted: &WhiteListedTokens) {
        let coinAddress = object::id(&coin);
        assert!(vector::contains(&whitelisted.address, &coinAddress) == true, ECoinNotWhiteListed);
        assert!(coin::value(&coin) == rps.stakes, ENotStakedAmount);
        assert!(rps.distributed == true, EGameFinishedAlready);
        if (rps.type == FRIENDONLY) {
            assert!(vector::contains(&friendlist.address, &challenger) == true, ENotFriend);
            rps.challenger = option::some(challenger); 
            rps.player_two_move = option::some(player_move);      
        }
        else if(rps.type == ONEONONE) {
            assert!(rps.challenger == option::some(challenger), ENotChallenger);
            rps.player_two_move = option::some(player_move);
        }
        else {
            rps.challenger = option::some(challenger);
            rps.player_two_move = option::some(player_move);
        };
        coin::put(&mut rps.balance, coin);
    }

    fun mutate_winner<T>(rps: &mut RPSGame<T>, salt: vector<u8>, ctx: &mut TxContext) {
        let RPSGame<T> {
                    id: _,
                    creator:_,
                    challenger,
                    message: _,
                    player_one_move: _,
                    player_two_move,
                    winner: _,
                    stakes,
                    balance: _,
                    distributed: _,
                    type: _,
                } = rps;
        let gesture_one = find_gesture(salt, &rps.player_one_move);
        assert!(gesture_one != HashNotMatched, EHashNotMatched);
        let gesture_two = *option::borrow(player_two_move);
        let total_balance = balance::value(&rps.balance);
        let coin = coin::take(&mut rps.balance, total_balance, ctx);
        let challenger_address = *(option::borrow(challenger));
        if (gesture_one == gesture_two){
            transfer::public_transfer(coin::split(&mut coin, *stakes, ctx), rps.creator);
            transfer::public_transfer(coin, challenger_address);
        }else{
            let playerMove = play(gesture_one, *option::borrow(player_two_move));
            let challenger_address = *(option::borrow(challenger));
            if (playerMove) {
                rps.winner = option::some(rps.creator);
                transfer::public_transfer(coin, rps.creator);
            }else{
                rps.winner = option::some(challenger_address);
                transfer::public_transfer(coin, challenger_address);
            };
        };
        rps.distributed = true; 
    }


    fun play(one: u8, two: u8): bool{
        if (one == ROCK && two == SCISSORS) { true }
        else if (one == PAPER && two == ROCK) { true }
        else if (one == SCISSORS && two == PAPER) {true }
        else { false }
    }

    fun find_gesture(salt: vector<u8>, hash: &vector<u8>): u8 {
        if (hash(ROCK, salt) == *hash) {
            ROCK
        } else if (hash(PAPER, salt) == *hash) {
            PAPER
        } else if (hash(SCISSORS, salt) == *hash) {
            SCISSORS
        } else {
           HashNotMatched
        }
    }

    fun hash(gesture: u8, salt: vector<u8>): vector<u8> {
        vector::push_back(&mut salt, gesture);
        hash::sha2_256(salt)
    } 
}