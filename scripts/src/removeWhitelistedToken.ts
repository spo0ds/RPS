import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, RPSCapId, WhiteListedTokensId } from '../utils/packageInfo';
dotenv.config();

async function removeToken() {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();

    tx.moveCall({
        target: `${packageId}::rps::remove_whitelisted_token`,
        arguments: [
            tx.object(RPSCapId),
            tx.object(WhiteListedTokensId),
        ],
        typeArguments: [`${packageId}::rps::RPS`],
    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });

    console.log({ result });
}

removeToken();
