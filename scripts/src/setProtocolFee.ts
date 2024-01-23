import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, RPSCapId, GameInfoId } from '../utils/packageInfo';
dotenv.config();

async function setProtocolFee(new_fee: number) {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageId}::rps::set_protocol_fee`,
        arguments: [
            tx.object(RPSCapId),
            tx.object(GameInfoId),
            tx.pure.u64(new_fee),
        ],
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}

setProtocolFee(10);
