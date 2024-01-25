import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { sha256 } from '@noble/hashes/sha256';
import { packageId, GameListId, WhiteListedTokensId, GameInfoId } from '../utils/packageInfo';
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";
dotenv.config();

// string => hex => sha256 => hex value => passss
async function createRpsGame(amount: number) {
    const stringToHex = (str: string, u8Value: number): Uint8Array => {
        const hex: number[] = [];

        // Convert the string characters to hex representation
        for (let i = 0; i < str.length; i++) {
            const charCode = str.charCodeAt(i);
            const hexValue = charCode.toString(16).padStart(2, '0');
            hex.push(parseInt(hexValue, 16));
        }

        // Convert the u8Value to its hexadecimal representation (u8 value should be between 0 and 255)
        if (u8Value >= 0 && u8Value <= 255) {
            const u8HexValue = u8Value.toString(16).padStart(2, '0');
            hex.push(parseInt(u8HexValue, 16));
        } else {
            throw new Error('Invalid u8 value. It should be between 0 and 255.');
        }

        // Create a Uint8Array from the array of numbers
        return new Uint8Array(hex);
    };
    const hashDigest = sha256(stringToHex("ram", 1));
    console.log(`hashDigest: ${hashDigest}`);
    console.log(typeof hashDigest);
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    // for rps coin
    // let coinId: string = (await client.getCoins({
    //     owner: keypair.getPublicKey().toSuiAddress(),
    //     coinType: `${packageId}::rps::RPS`,
    // })).data[0].coinObjectId;
    // const coin = tx.splitCoins(coinId, [tx.pure(amount)]);

    // for sui only
    const coin = tx.splitCoins(tx.gas, [tx.pure(amount)]);

    tx.moveCall({
        target: `${packageId}::rps::create_game`,
        arguments: [
            tx.pure([]),
            tx.pure.string(''),
            tx.pure(Array.from(hashDigest)),
            tx.pure.u64(10000000),
            coin,
            tx.pure.u8(6),
            tx.object(GameListId),
            tx.object(WhiteListedTokensId),
            tx.object(GameInfoId),
            tx.object(SUI_CLOCK_OBJECT_ID),
        ],
        // typeArguments: [`${packageId}::rps::RPS`]
        typeArguments: [`0x2::sui::SUI`]

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
            if (await item.objectType === `${packageId}::rps::RPSGame<0x2::sui::SUI>`) {
                RPSId = String(item.objectId);
            }
        }
    }
    console.log(`RPSId: ${RPSId}`);
}
createRpsGame(10000000);