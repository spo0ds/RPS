import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { sha256 } from '@noble/hashes/sha256';
import { packageId, GameListId } from '../utils/packageInfo';
dotenv.config();

 // string => hex => sha256 => hex value => passss
async function create_rps_game(amount: number) {
    const stringToHex = (str: string): Uint8Array => {
        const hex: number[] = [];
        for (let i = 0; i < str.length; i++) {
            const charCode = str.charCodeAt(i);
            const hexValue = charCode.toString(16);

            // Pad with zeros to ensure two-digit representation
            const paddedHexValue = hexValue.padStart(2, '0');

            // Convert the padded hex value to a number and push it to the array
            hex.push(parseInt(paddedHexValue, 16));
        }

        // Create a Uint8Array from the array of numbers
        return new Uint8Array(hex);
    };
   const hashDigest = sha256(stringToHex("cedac40ea1be07aa3e410ef6fad369e8c95bcff8"));
   console.log(`hashDigest: ${hashDigest}`);
   console.log(typeof hashDigest);
 // const hashDigest = "c6130d0f59a390c51910707fba40f1d1013054be19e7a87a7294e15164c85992";
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    const coin = tx.splitCoins(tx.gas, [tx.pure(amount)]);
    tx.moveCall({
        target: `${packageId}::rps::createGame`,
        arguments: [
            tx.pure.string(''),
            tx.pure.string(''),
            tx.pure.u8(0),
            tx.pure.u64(10000000),
            coin,
            tx.pure.string('everyone'),
            tx.object(GameListId),
        ]
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log(result.digest);
    const digest_ = result.digest;

    const txn = await client.getTransactionBlock({
        digest: String(digest_),
        // only fetch the effects and objects field
        options: {
            showEffects: true,
            showInput: false,
            showEvents: false,
            showObjectChanges: true,
            showBalanceChanges: false,
        },
    });
    let output: any;
    output = txn.objectChanges;
    let RPSId;
    for (let i = 0; i < output.length; i++) {
        const item = output[i];
        if (await item.type === 'created') {
            if (await item.objectType === `${packageId}::rps::RPS`) {
                RPSId = String(item.objectId);
            }
        }
    }
    console.log(`RPSId: ${RPSId}`);
}
create_rps_game(10000000);