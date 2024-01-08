module rps::rps{
    use std::string;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option};
    use sui::balance::{Balance};
    use sui::sui::SUI;
    use sui::transfer;
    use std::vector;
    use sui::dynamic_object_field as ofield;
    use sui::coin::{Self, Coin};

    // const ROCK: u8 = 0;
    // const PAPER: u8 = 1;
    // const SCISSORS: u8 = 2;

    const ENotStakedAmount: u64 = 3;
    const EZeroStakedNotAllowed : u64 = 4;

    struct RPS has key,store{
        id: UID,
        creator:address,
        challenger:Option<address>,
        message:Option<string::String>,
        player_one_move: vector<u8>,
        player_two_move: Option<vector<u8>>,
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

     fun mutate_move(rps: &mut RPS, player_move: vector<u8>, coin:Coin<SUI>, challenger: address) {
        rps.player_two_move = option::some(player_move);
        rps.challenger = option::some(challenger);
        coin::put(&mut rps.balance, coin); 
    }

    public entry fun play_game(child_id: ID, parent: &mut GameList, player_move:vector<u8>, coin:Coin<SUI>,ctx: &mut TxContext){
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
}