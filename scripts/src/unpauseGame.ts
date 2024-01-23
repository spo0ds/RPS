import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, RPSCapId, GameInfoId } from '../utils/packageInfo';
dotenv.config();

async function unpauseRpsGame() {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageId}::rps::unpause_game`,
        arguments: [
            tx.object(RPSCapId),
            tx.object(GameInfoId),
        ],
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}
unpauseRpsGame();
