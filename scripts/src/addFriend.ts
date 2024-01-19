import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, FriendListId, FriendCapId } from '../utils/packageInfo';
dotenv.config();

async function addFriend(address1: String) {
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();

    tx.moveCall({
        target: `${packageId}::rps::update_to_myfriend_list`,
        arguments: [
            tx.object(FriendCapId),
            tx.object(FriendListId),
            tx.pure([address1], "vector<address>")
            ,
        ]
    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });

    console.log({ result });
}

addFriend("0x821febff0631744c231a0f696f62b72576f2634b2ade78c74ff20f1df97fc9bf");
