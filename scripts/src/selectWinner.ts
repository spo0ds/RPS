import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, RPSId, GameListId, GameInfoId } from '../utils/packageInfo';
dotenv.config();

// string => hex => sha256 => hex value => passss
async function selectWinner() {
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
    const hashDigest = stringToHex("ram");
    console.log(`hashDigest: ${hashDigest}`);
    const { keypair, client } = getExecStuff();
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageId}::rps::select_winner`,
        arguments: [
            tx.pure.address(RPSId),
            tx.pure(Array.from(hashDigest)),
            tx.object(GameListId),
            tx.object(GameInfoId),
        ],
        typeArguments: [`${packageId}::rps::RPS`]
    });
    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}
selectWinner();