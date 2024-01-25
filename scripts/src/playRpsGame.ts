import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { packageId, RPSId, GameListId, FriendListId, WhiteListedTokensId, GameInfoId } from '../utils/packageInfo';
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";
dotenv.config();

// string => hex => sha256 => hex value => passss
async function playRpsGame(amount: number) {
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
        target: `${packageId}::rps::play_game`,
        arguments: [
            tx.pure.address(RPSId),
            tx.object(GameListId),
            tx.pure.u8(1),
            coin,
            tx.object(FriendListId),
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
    console.log({ result });
}
playRpsGame(10000000);