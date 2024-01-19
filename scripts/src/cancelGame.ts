import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, RPSId, GameListId } from '../utils/packageInfo';
dotenv.config();

async function cancelGame() {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageId}::rps::cancel_game`,
        arguments: [
            tx.object(GameListId),
            tx.pure.address(RPSId)
        ],
        typeArguments: ["0x2::sui::SUI"]
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}
cancelGame();