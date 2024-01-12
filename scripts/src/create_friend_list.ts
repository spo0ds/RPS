import { TransactionBlock } from '@mysten/sui.js/transactions';
import { SuiObjectChangePublished } from '@mysten/sui.js/client';

import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId } from '../utils/packageInfo';
dotenv.config();

async function create_friend_list() {
    try {
        const { keypair, client } = getExecStuff();
        const tx = new TransactionBlock();
        tx.moveCall({
            target: `${packageId}::rps::createFriendlist`,
            arguments: []
        });
        const result = await client.signAndExecuteTransactionBlock({
            signer: keypair,
            transactionBlock: tx,
            options: {
                showEffects: true,
                showObjectChanges: true,
            }
        });
        console.log(result.digest);
        const digest_ = result.digest;
        if (!digest_) {
            console.log("Digest is not available");
            throw new Error("Digest is not available");
        }
        const txn = await client.getTransactionBlock({
            digest: String(digest_),
            options: {
                showEffects: true,
                showInput: false,
                showEvents: false,
                showObjectChanges: true,
                showBalanceChanges: false,
            },
        });
        let FriendListId;
        let FriendListCapId;
        let output: any;
        output = txn.objectChanges;
        for (let i = 0; i < output.length; i++) {
            const item = output[i];
            if (item.type === 'created') {
                if (item.objectType === `${packageId}::rps::FriendList`) {
                    FriendListId = String(item.objectId);
                }
                if (item.objectType === `${packageId}::rps::FriendCap`) {
                    FriendListCapId = String(item.objectId);
                }
            }
        }

        if (!FriendListId || !FriendListCapId) {
            console.log("Friend list or its cap is empty");
            throw new Error("Friend list or its cap is empty");
        }

        console.log("FriendListId:", FriendListId);
        console.log("FriendListCapId:", FriendListCapId);

        return { FriendListId, FriendListCapId };
    } catch (error: any) {
        console.error("Error:", error.message);
    }
}

create_friend_list();
