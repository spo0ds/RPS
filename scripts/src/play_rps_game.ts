import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { sha256 } from '@noble/hashes/sha256';
import { packageId, RPSId, GameListId } from '../utils/packageInfo';
dotenv.config();

 // string => hex => sha256 => hex value => passss
async function play_rps_game(amount: number ) {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    const coin = tx.splitCoins(tx.gas, [tx.pure(amount)]);
    tx.moveCall({
        target: `${packageId}::rps::play_game`,
        arguments: [
            tx.pure.address(RPSId),
            tx.object(GameListId),
            tx.pure.u8(2),
            coin
        ]
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}
play_rps_game(10000000);