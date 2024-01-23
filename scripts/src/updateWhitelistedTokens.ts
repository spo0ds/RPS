import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, RPSCapId, WhiteListedTokensId } from '../utils/packageInfo';
dotenv.config();

async function updateToken() {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageId}::rps::update_whitelist_token`,
        arguments: [
            tx.object(RPSCapId),
            tx.object(WhiteListedTokensId)
        ],
        typeArguments: [`${packageId}::rps::RPS`],
        // typeArguments: ["0x2::sui::SUI"],
    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });

    console.log({ result });
}

updateToken();
