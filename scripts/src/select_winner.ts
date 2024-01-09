import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { sha256 } from '@noble/hashes/sha256';
import { packageId, RPSId, GameListId } from '../utils/packageInfo';
dotenv.config();

 // string => hex => sha256 => hex value => passss
async function play_rps_game() {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageId}::rps::select_winner`,
        arguments: [
            tx.pure.address('0x4ae52208823cc750e0bf3d9ffce8e652e97975424dcd54b2e8bd3e9e0766891c'),
            tx.object(RPSId),
            tx.object(GameListId),
        ]
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}
play_rps_game();