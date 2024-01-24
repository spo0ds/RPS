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
    use std::type_name::{Self, TypeName};
    use sui::math;
    use sui::clock::{Self, Clock};

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS 
    ////////////////////////////////////////////////////////////////////////// */
    
    const ROCK: u8 = 0;
    const PAPER: u8 = 1;
    const SCISSORS: u8 = 2;
    const HashNotMatched: u8 = 3;
    const FRIENDONLY: u8 = 4;
    const ONEONONE: u8 = 5;

    /*//////////////////////////////////////////////////////////////////////////
                                     ERRORS
    ////////////////////////////////////////////////////////////////////////// */

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
    const EZamePaused: u64 = 17;
    const EPlayer2AlreadyPlayed: u64 = 18;

    /// @dev It is the type of witness and is intended to be used only once

    struct RPS has drop {}

    /// @dev It is the RPS Game Object Details 
    struct RPSGame<phantom T> has key,store{
        id: UID,
        creator:address,
        challenger:Option<address>,
        message:Option<string::String>,
        player_one_move: vector<u8>,
        player_two_move: Option<u8>,
        winner : Option<address>,
        stakes:u64,
        timestamp: u64,
        balance: Balance<T>,
        distributed: bool,
        type: u8,
    }

    /// @dev GameList contains the rps_game_count and used for Dynamical Object Properties
    struct GameList has key{
        id: UID,
        rps_game_count:  u64,
    }

    /// @dev FriendList contains array of Friend that user consist with
    struct FriendList has key {
        id: UID,
        address: vector<address>,
    }

    /// @dev Token that are allowed to stake should whiteList
    struct WhiteListedTokens has key {
        id: UID,
        list: vector<TypeName>,
    }

    /// @dev GameInfo represent the state of GameInfo, treasury_address and protocol_fee
    struct GameInfo has key{
        id: UID,
        pause: bool,
        treasury_address: address,
        protocol_fee: u64,
    }


    /// @dev Capability for User to update, add, delete new friend 
    struct FriendCap has key{
        id: UID, 
    }

    /// @dev Capability for deployer or Admin to select winner 
    struct RPSGameCap has key{
        id: UID, 
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    ////////////////////////////////////////////////////////////////////////// */

    /**
    * @dev emit ShareObject {GameList, WhiteListedTokens} and transfer {RPSGameCap, TreasuryCap} to deployer
    * @param witness of the RPS which allows to drop and can be called only once
    */
    fun init(witness: RPS, ctx:&mut TxContext) {
        let id = object::new(ctx);
        transfer::share_object(GameList {
            id,
            rps_game_count: 0u64,
        });
        transfer::transfer(RPSGameCap{
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        transfer::share_object(GameInfo{
            id: object::new(ctx),
            pause: false,
            treasury_address: tx_context::sender(ctx),
            protocol_fee : 5,
        });

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
            list: vector::empty(),
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MINT NEW TOKEN
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev allows to min the new token
    * @param treasury_cap capablity to mint the new token
    * @param amount number of token to be minted 
    * @param recipient address of recipient who get the desired token
    */
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<RPS>, 
        amount: u64, 
        recipient: address, 
        ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SET TREASURY OWNER 
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev allow to set the treasury owner 
    * @param _cap Capability of RPSGame 
    * @param game_info is the Shared object which shows the details of protocol admin, protocol fee and state of the game
    * @param new_owner address of the new owner 
    */

    public fun set_treasury_owner(_cap:&RPSGameCap, game_info: &mut GameInfo, new_owner: address){
        game_info.treasury_address = new_owner;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SET PROTOCOL FEE  
    ////////////////////////////////////////////////////////////////////////// */
    /** 
    * @dev allow to set the protocol fee 
    * @param _cap Capability of RPSGame 
    * @param game_info is the Shared object which shows the details of protocol admin, protocol fee and state of the game
    * @param new_fee_percentage is the protocol fee 
    */
    public fun set_protocol_fee(_cap:&RPSGameCap, game_info: &mut GameInfo, new_fee_percentage: u64){
        game_info.protocol_fee = new_fee_percentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PAUSE GAME   
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev allow to pause the game
    * @param _cap Capability of RPSGame
    * @param game_info is the Shared object which shows the details of protocol admin, protocol fee and state of the game
    */

    public fun pause_game(_cap:&RPSGameCap, game_info: &mut GameInfo){
        game_info.pause = true;
    }

     /*//////////////////////////////////////////////////////////////////////////
                                UNPAUSE GAME   
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev allow to unpause the game
    * @param _cap Capability of RPSGame
    * @param game_info is the Shared object which shows the details of protocol admin, protocol fee and state of the game
    */
    public fun unpause_game(_cap:&RPSGameCap, game_info: &mut GameInfo){
        game_info.pause = false;
    }

    
    /*//////////////////////////////////////////////////////////////////////////
                                   WHITELIST NEW TOKEN 
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev allows to append the token_id in WhiteListedToken shared object
    * @param _cap RPSGamecap Capability 
    * @param whitelisted: Shareobject Id of WhiteListed Token
    */
    public fun update_whitelist_token<T>(_cap:&RPSGameCap, whitelisted: &mut WhiteListedTokens) {
        vector::push_back(&mut whitelisted.list, type_name::get<T>());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   REMOVE THE EXISTING TOKEN
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev allows to remove the token_id from WhiteListedToken shared object
    * @param _cap RPSGamecap Capability 
    * @param whitelisted: Shareobject Id of WhiteListed Token
    */

    public fun remove_whitelisted_token<T>(_cap: &RPSGameCap, whitelisted: &mut WhiteListedTokens) {
        let (found, index) = vector::index_of(&whitelisted.list, &type_name::get<T>());
        assert!(found, ETokenNotPresent);
        vector::remove(&mut whitelisted.list, index);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CREATE FRIENDLIST SHARED OBJECT ID
    ////////////////////////////////////////////////////////////////////////// */
    /// @dev Create { FriendList Shared Object Id } and transfer `FriendCap` to caller
    public entry fun create_friendlist(ctx:&mut TxContext){
         transfer::transfer(FriendCap{
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::share_object(FriendList{
            id: object::new(ctx),
            address: vector::empty(),
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  UDPATE FRIEND LIST 
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev update the friend list 
    * @param _cap FriendCap Capability to trigger the update_to_myfriend_list
    * @param friendlist share object of invidual user {note every user got their different friendlist share object}
    * @addresses collection of friend in vector to pushin friendlist
    */
    public entry fun update_to_myfriend_list(_cap:&FriendCap, friendlist: &mut FriendList, addresses: vector<address>) {
        vector::append(&mut friendlist.address, addresses); 
    }

    /*//////////////////////////////////////////////////////////////////////////
                        REMOVE FRIEND FROM FRIENDLIST SHARED OBJECT
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev remove the friend the friend list 
    * @param _cap FriendCap Capability to trigger the remove_friend
    * @param friendlist share object of invidual user {note every user got their different friendlist share object}
    * @friendAddress: that  
    */

    public entry fun remove_friend(_cap: &FriendCap, friendlist: &mut FriendList, friendAddress: address) {
        let (found, index) = vector::index_of(&friendlist.address, &friendAddress);
        assert!(found, EFriendNotPresent);
        vector::remove(&mut friendlist.address, index);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               CREATE NEW RPS GAME
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev Create new RPS Game according to the Challenger Type
    * @param challenger It is the challenger address where it set according to challenger Type ie. 1. ONEONONE 2.FRIENDONLY 3. FREEFORALL
    * @param message it is the message for the oponent while creating a game and it is optional
    * @param player_one_move it the move by the creater of the game which is confidential so here salt + hashing is done and pushed to blockchain
    * @parma stakes amount that is stakes by game creator / player one 
    * @param coin that is must be placed while creating the game [ must be equal to stakes ]
    * @param type Challenge type ie 1. ONEONONE 2. FRIENDONLY 3. FREEFORALL
    * @param gameList_object is Shared Object 
    * @param whitelisted is the shared object id of whitelist token
    * @param game_info is the shared object which shows the details of protocol admin, protocol fee and state of the game
    */

    public entry fun create_game<T>(challenger:Option<address>, message:Option<string::String>, player_one_move: vector<u8>, stakes:u64, coin: Coin<T>, type: u8, gameList_object: &mut GameList, whitelisted: &WhiteListedTokens, game_info: &GameInfo, clock: &Clock, ctx: &mut TxContext){
        assert!(game_info.pause == false, EZamePaused);
        assert!(stakes > 0, EZeroStakedNotAllowed);
        assert!(vector::contains(&whitelisted.list, &type_name::get<T>()) == true, ECoinNotWhiteListed);
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
            timestamp: clock::timestamp_ms(clock),
            balance: coin::into_balance(coin),
            distributed: false,
            type: type,
        };
        let rsp_id = object::id(&rsp);
        ofield::add(&mut gameList_object.id, rsp_id, rsp);
        gameList_object.rps_game_count = gameList_object.rps_game_count + 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               PLAY RPS GAME
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev Play the RPS Game According to the challenger TYPE
    * @param child_ID is the ID of the created RPS Game object.
    * @param player_move is the move of the Second Player ie. ROCK / PAPER / SCISSORS
    * @param coin is the particular amount that Second Player want to Stake and play and it is of Generic Type 
    * @param whitelisted is the share object ID to get the whiteListed Token details
    * @param game_info is the shared object which shows the details of protocol admin, protocol fee and state of the game
    */

    public entry fun play_game<T>(child_id: ID, parent: &mut GameList, player_move:u8, coin:Coin<T>, friendlist: &FriendList, whitelisted: &WhiteListedTokens, game_info: &GameInfo, clock: &Clock, ctx: &mut TxContext){
         mutate_move(ofield::borrow_mut<ID, RPSGame<T>>(
            &mut parent.id,
            child_id,
        ), player_move, coin , friendlist, tx_context::sender(ctx), whitelisted, game_info, clock); 
    }

    /*//////////////////////////////////////////////////////////////////////////
                               SELECT WINNER 
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev select winner determine the particular RPS Game Winner
    * @param _cap is the capability ID only admin can select_winner cause RPSGameCap is transfer to admin
    * @param child_id is the created game RPS object ID
    * @param salt is secret key to hide the RPS game creator moves ie Player One move
    * @param gameList_object is Shared Object ID to track all the created Game and its count
    * @param game_info is the Shared object which shows the details of protocol admin, protocol fee and state of the game
    */
    public entry fun select_winner<T>(child_id: ID, salt:vector<u8>, gameList_object: &mut GameList, game_info: &GameInfo, clock: &Clock, ctx: &mut TxContext) {
        mutate_winner(
            ofield::borrow_mut<ID, RPSGame<T>>(&mut gameList_object.id, child_id),
            salt,
            game_info,
            clock,
            ctx,
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                               CANCEL THE RPS GAME  
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev Creator can Cancel the created RPS Game 
    * @param parent is Shared Object ID to track all the created Game and its count
    * @param child_id is created RPS game ID
    */
    entry public fun cancel_game<T>(parent: &mut GameList, child_id: ID, ctx: &mut TxContext) {
        let RPSGame<T> {
            id,
            creator,
            challenger: _,
            message: _,
            player_one_move: _,
            player_two_move,
            winner: _,
            stakes: _,
            timestamp: _,
            balance,
            distributed,
            type:_,
        } = ofield::remove(&mut parent.id, child_id);
        assert!(creator == tx_context::sender(ctx), ENotCreator);
        assert!(distributed == false, EGameFinishedAlready);
        assert!(player_two_move == option::none(), EPlayer2AlreadyPlayed);
        let coin = sui::coin::from_balance(balance, ctx);
        sui::transfer::public_transfer(coin, creator);
        object::delete(id);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               MUTATE_MOVE
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev MUTATE_MOVE is the basically used for Dynamically object Field Purpose to link in overall GameList Shared Object
    * @param rps is the RPSGame object ID 
    * @param player_move is the move of the Second Player ie. ROCK / PAPER / SCISSORS 
    * @param coin is the particular amount that Second Player want to Stake and play and it is of Generic Type 
    * @param friendlist is the sharedObject ID to get the collection of the creator FriendLIst
    * @param challenger is the player two addresses who is about to play game
    * @param whitelisted is the shared object ID to get the whiteListed Token details
    * @param game_info is the shared object which shows the details of protocol admin, protocol fee and state of the game
    */
    fun mutate_move<T>(rps: &mut RPSGame<T>, player_move: u8, coin:Coin<T>, friendlist: & FriendList, challenger: address, whitelisted: &WhiteListedTokens, game_info: &GameInfo, clock: &Clock) {
        assert!(game_info.pause == false, EZamePaused);
        assert!(vector::contains(&whitelisted.list, &type_name::get<T>()) == true, ECoinNotWhiteListed);        
        assert!(coin::value(&coin) == rps.stakes, ENotStakedAmount);
        assert!(rps.distributed == false, EGameFinishedAlready);
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
        rps.timestamp = clock::timestamp_ms(clock); 
        coin::put(&mut rps.balance, coin);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               MUTATE_WINNER
    ////////////////////////////////////////////////////////////////////////// */
    /** 
    * @dev mutate_winner mutate the DOF object field for select winner function call
    * @param rps is the RPSGame object ID 
    * @param salt is secret key to hide the RPS game creator moves ie Player One move
    * @param game_info is the shared object which shows the details of protocol admin, protocol fee and state of the game
    */
    fun mutate_winner<T>(rps: &mut RPSGame<T>, salt: vector<u8>, game_info: &GameInfo, clock: &Clock, ctx: &mut TxContext) {
        let RPSGame<T> {
                    id: _,
                    creator:_,
                    challenger,
                    message: _,
                    player_one_move: _,
                    player_two_move,
                    winner: _,
                    stakes,
                    timestamp,
                    balance: _,
                    distributed,
                    type: _,
                } = rps;
        assert!(*distributed == false, EGameFinishedAlready);
        if(*player_two_move != option::none() && *timestamp + clock::timestamp_ms(clock)>= 86_400_000) {
            let total_balance = balance::value(&rps.balance);
            let challenger_address = *(option::borrow(challenger));
            let coin = coin::take(&mut rps.balance, total_balance, ctx);
            transfer::public_transfer(coin, challenger_address);
        }else {
            let gesture_one = find_gesture(salt, &rps.player_one_move);
            assert!(gesture_one != HashNotMatched, EHashNotMatched);
            let gesture_two = *option::borrow(player_two_move);
            let total_balance = balance::value(&rps.balance);
            let challenger_address = *(option::borrow(challenger));
            if (gesture_one == gesture_two){
                let coin = coin::take(&mut rps.balance, total_balance, ctx);
                transfer::public_transfer(coin::split(&mut coin, *stakes, ctx), rps.creator);
                transfer::public_transfer(coin, challenger_address);
            }else{
                let protocol_amount = math::divide_and_round_up(game_info.protocol_fee * total_balance, 100);
                let fee_amount = coin::take(&mut rps.balance, protocol_amount, ctx);
                transfer::public_transfer(fee_amount, game_info.treasury_address);
                let winner_amount = coin::take(&mut rps.balance, math::diff(total_balance, protocol_amount) , ctx);
                let playerMove = play(gesture_one, *option::borrow(player_two_move));
                let challenger_address = *(option::borrow(challenger));
                if (playerMove) {
                    rps.winner = option::some(rps.creator);
                    transfer::public_transfer(winner_amount, rps.creator);
                }else{
                    rps.winner = option::some(challenger_address);
                    transfer::public_transfer(winner_amount, challenger_address);
                };
            };
        rps.distributed = true; 
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                        CALCULATE THE WINNER 
    ////////////////////////////////////////////////////////////////////////// */
    /**
    * @dev get the move from both player can
    * @param one move of the player one represent in u8 type.
    * @param two move of the player  two represent in u8 type.
    * @return the move select is winner of not in boolean type.
    */
    fun play(one: u8, two: u8): bool{
        if (one == ROCK && two == SCISSORS) { true }
        else if (one == PAPER && two == ROCK) { true }
        else if (one == SCISSORS && two == PAPER) {true }
        else { false }
    }

    /*//////////////////////////////////////////////////////////////////////////
                        FIND THE GESTURE
    ////////////////////////////////////////////////////////////////////////// */
    /** 
    * @dev basically this function is used to hide player one move and calculate the hash and salt and select the move provide by player one
    * @param salt is secret key to hide the RPS game creator moves ie Player One move
    * @param Hash generated using that salt key 
    * @return the move based on the salt and hash
    */

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

    /*//////////////////////////////////////////////////////////////////////////
                        HASH FUNCTION
    ////////////////////////////////////////////////////////////////////////// */
    /** 
    * @dev SHA256 is used to hash the salt and gesture 
    * @param gesture is the move type ROCK/PAPER/SCISSORS
    * @param salt is the key represent in vector<u8>
    * @return sha256 hash of gesture and salt embedded hash
    */

    fun hash(gesture: u8, salt: vector<u8>): vector<u8> {
        vector::push_back(&mut salt, gesture);
        hash::sha2_256(salt)
    } 
}