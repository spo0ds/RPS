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
    const ERROR: u8 = 6;
    const NONE: u8 = 7;

    const ENotStakedAmount: u64 = 3;
    const EZeroStakedNotAllowed : u64 = 4;

    struct RPS has key,store{
        id: UID,
        creator:address,
        challenger:Option<address>,
        message:Option<string::String>,
        player_one_move: vector<u8>,
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

    struct FriendList has key {
        id: UID,
        address: vector<address>,
    }

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

    public entry fun createGame(challenger:Option<address>,message:Option<string::String>, player_one_move: vector<u8>,stakes:u64, coin: Coin<SUI>, type: string::String, gameList_object: &mut GameList, ctx: &mut TxContext){
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

    public entry fun addToMyFriendList(addresses: vector<address>, ctx: &mut TxContext){
        let whitelist = FriendList{
            id: object::new(ctx),
            address: addresses,
        };
        transfer::transfer(whitelist, tx_context::sender(ctx));
    }

    public entry fun updateToMyFriendList(friendlist: &mut FriendList, addresses: vector<address>) {
        vector::append(&mut friendlist.address, addresses); 
    }

    public entry fun select_winner(rps: &mut RPS, salt_1: vector<u8>, gameList_object: &mut GameList, ctx: &mut TxContext){
        let RPS { 
            id: _,
            creator: _, 
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
        let gesture_one = find_gesture(salt_1, player_one_move);
        let playerMove = play(gesture_one, *option::borrow(player_two_move));
        let total_balance = balance::value(&rps.balance);
        let coin = coin::take(&mut rps.balance, total_balance, ctx);
        if (gesture_one == playerMove) {
            mutate_winner(ofield::borrow_mut<ID, RPS>(
            &mut gameList_object.id,
            object::id(rps)
            ), rps.creator); 
            transfer::public_transfer(coin, rps.creator);
        }else if (option::borrow(player_two_move) == &playerMove){
            mutate_winner(ofield::borrow_mut<ID, RPS>(
            &mut gameList_object.id,
            object::id(rps)), *(option::borrow(challenger))); 
            transfer::public_transfer(coin, *(option::borrow(challenger)));
        }else{
            transfer::public_transfer(coin::split(&mut coin, *stakes, ctx), rps.creator);
            transfer::public_transfer(coin, *(option::borrow(challenger)));
             mutate_distributed(ofield::borrow_mut<ID, RPS>(
            &mut gameList_object.id,
            object::id(rps))); 
        }
    }

    fun mutate_winner(rps: &mut RPS, winner: address) {
        rps.winner = option::some(winner);
        rps.distributed = true;
    }

    fun mutate_distributed(rps: &mut RPS) {
        rps.distributed = true;
    }

    fun play(one: u8, two: u8):  u8{
        if (one == ROCK && two == SCISSORS) { ROCK }
        else if (one == PAPER && two == ROCK) { PAPER }
        else if (one == SCISSORS && two == PAPER) { SCISSORS }
        else {NONE }
    }

    fun find_gesture(salt: vector<u8>, hash: &vector<u8>): u8 {
        if (hash(ROCK, salt) == *hash) {
            ROCK
        } else if (hash(PAPER, salt) == *hash) {
            PAPER
        } else if (hash(SCISSORS, salt) == *hash) {
            SCISSORS
        } else {
           ERROR
        }
    }

    fun hash(gesture: u8, salt: vector<u8>): vector<u8> {
        vector::push_back(&mut salt, gesture);
        hash::sha2_256(salt)
    }
}