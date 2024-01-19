import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, TreasuryCapId } from '../utils/packageInfo';
dotenv.config();

async function mintToken(amount: string, recipientAddress: string) {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();

    tx.moveCall({
        target: `${packageId}::rps::mint`,
        arguments: [
            tx.object(TreasuryCapId),
            tx.pure.u64(amount),
            tx.pure.address(recipientAddress),
        ]
    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });

    console.log({ result });
}

// mintToken("10000000000", "0x3661c4815e13c149514860d040a7edb64cb115d0610a532a5cb6101546bd5738");
mintToken("10000000000", "0x821febff0631744c231a0f696f62b72576f2634b2ade78c74ff20f1df97fc9bf");

