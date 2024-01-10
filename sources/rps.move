module rps::rps{
    use std::string;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::transfer;
    use std::vector;
    use sui::dynamic_object_field as ofield;
    use sui::coin::{Self, Coin};
    use std::hash;

    const ROCK: u8 = 0;
    const PAPER: u8 = 1;
    const SCISSORS: u8 = 2;
    const ERROR: u8 = 5;
    const NONE: u8 = 6;

    const ENotStakedAmount: u64 = 3;
    const EZeroStakedNotAllowed : u64 = 4;
    const EGuestureFailed: u64 = 7;

    struct RPS has key,store{
        id: UID,
        creator:address,
        challenger:Option<address>,
        message:Option<string::String>,
        player_one_move: u8,
        player_two_move: Option<u8>,
        winner : Option<address>,
        stakes:u64,
        balance: Balance<SUI>,
        distributed: bool,
        type: string::String,
    }

    struct GameList has key{
        id: UID,
        rps_game_count:  u64,
        // rps dynamically gets added
    }

    // struct FriendList has key {
    //     id: UID,
    //     address: vector<address>,
    // }

    struct RPSCap has key{
        id: UID, 
    }

    fun init(ctx:&mut TxContext) {
        let id = object::new(ctx);
        transfer::share_object(GameList {
            id,
            rps_game_count: 0u64,
        });
        transfer::transfer(RPSCap{
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    public entry fun createGame(challenger:Option<address>,message:Option<string::String>, player_one_move: u8,stakes:u64, coin: Coin<SUI>, type: string::String, gameList_object: &mut GameList, ctx: &mut TxContext){
        assert!(stakes > 0, EZeroStakedNotAllowed);
        assert!(coin::value(&coin) == stakes, ENotStakedAmount);
        let rsp = RPS{
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

     fun mutate_move(rps: &mut RPS, player_move: u8, coin:Coin<SUI>, challenger: address) {
        assert!(coin::value(&coin) == rps.stakes, ENotStakedAmount);
        rps.player_two_move = option::some(player_move);
        rps.challenger = option::some(challenger);
        coin::put(&mut rps.balance, coin); 
    }

    public entry fun play_game(child_id: ID, parent: &mut GameList, player_move:u8, coin:Coin<SUI>,ctx: &mut TxContext){
         mutate_move(ofield::borrow_mut<ID, RPS>(
            &mut parent.id,
            child_id,
        ), player_move, coin , tx_context::sender(ctx)); 
    }

    // public entry fun addToMyFriendList(addresses: vector<address>, ctx: &mut TxContext){
    //     let whitelist = FriendList{
    //         id: object::new(ctx),
    //         address: addresses,
    //     };
    //     transfer::transfer(whitelist, tx_context::sender(ctx));
    // }

    // public entry fun updateToMyFriendList(friendlist: &mut FriendList, addresses: vector<address>) {
    //     vector::append(&mut friendlist.address, addresses); 
    // }

    
    public entry fun select_winner(child_id: ID, gameList_object: &mut GameList,ctx: &mut TxContext) {
        mutate_winner(
            ofield::borrow_mut<ID, RPS>(&mut gameList_object.id, child_id),
            ctx,
        );
    }


    fun mutate_winner(rps: &mut RPS, ctx: &mut TxContext) {
        let RPS {
                    id: _,
                    creator,
                    challenger,
                    message: _,
                    player_one_move,
                    player_two_move,
                    winner: _,
                    stakes,
                    balance: _,
                    distributed: _,
                    type: _,
                } = rps;

        let gesture_one = *player_one_move;
        let gesture_two = *option::borrow(player_two_move);
        assert!(gesture_one != ERROR, EGuestureFailed);
        let playerMove = play(gesture_one, *option::borrow(player_two_move));
        let playerMove2 = play(*option::borrow(player_two_move), gesture_one);
        let challenger_address = *(option::borrow(challenger));

        let total_balance = balance::value(&rps.balance);
        let coin = coin::take(&mut rps.balance, total_balance, ctx);
        if (playerMove) {
                 // let temp_winner = option::some(rps.creator);
                rps.winner = option::some(rps.creator);
                transfer::public_transfer(coin, rps.creator);
                rps.distributed = true;
            } else if (playerMove2) {
                rps.winner = option::some(challenger_address);
                transfer::public_transfer(coin, challenger_address);
                rps.distributed = true;
         } 
         else {
                transfer::public_transfer(coin::split(&mut coin, *stakes, ctx), rps.creator);
                transfer::public_transfer(coin, challenger_address);
                rps.distributed = true; 
        } 
    }


    fun mutate_distributed(rps: &mut RPS) {
        rps.distributed = true;
    }

    fun play(one: u8, two: u8): bool{
        if (one == ROCK && two == SCISSORS) { true }
        else if (one == PAPER && two == ROCK) { true }
        else if (one == SCISSORS && two == PAPER) {true }
        else { false }
    }

    // fun find_gesture(salt: vector<u8>, hash: &vector<u8>): u8 {
    //     if (hash(ROCK, salt) == *hash) {
    //         ROCK
    //     } else if (hash(PAPER, salt) == *hash) {
    //         PAPER
    //     } else if (hash(SCISSORS, salt) == *hash) {
    //         SCISSORS
    //     } else {
    //        ERROR
    //     }
    // }

    // fun hash(gesture: u8, salt: vector<u8>): vector<u8> {
    //     vector::push_back(&mut salt, gesture);
    //     hash::sha2_256(salt)
    // }
}