import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, RPSCapId, GameInfoId } from '../utils/packageInfo';
dotenv.config();

async function setTreasuryOwner(new_owner: string) {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageId}::rps::set_treasury_owner`,
        arguments: [
            tx.object(RPSCapId),
            tx.object(GameInfoId),
            tx.pure.address(new_owner),
        ],
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}

setTreasuryOwner("0x821febff0631744c231a0f696f62b72576f2634b2ade78c74ff20f1df97fc9bf");
