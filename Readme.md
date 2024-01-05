rps_gaame_registry should hold all the created games
    it's a shared object
game struct 
    game_creator
    challenger
    option : message
treasury struct
        player table
        stakes
        
while initiating game, creator creates treasury, fill treasury metadata, stakes amount of sui and gives his/her moves which is encrypted.
challenger also deposits same amount in treasury and gives his/her move.
treasury ma constraints- match between and winner only gets the reward.
