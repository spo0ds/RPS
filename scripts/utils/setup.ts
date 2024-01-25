import { SuiObjectChangePublished } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import getExecStuff from './execstuff';

const { execSync } = require('child_process');

function sleep(ms: number): Promise<void> {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    });
}

const getPackageId = async () => {
    try {
        const { keypair, client } = getExecStuff();
        const account = "0x3661c4815e13c149514860d040a7edb64cb115d0610a532a5cb6101546bd5738";
        const packagePath = process.cwd();
        const { modules, dependencies } = JSON.parse(
            execSync(`sui move build --dump-bytecode-as-base64 --path ${packagePath}`, {
                encoding: "utf-8",
            })
        );
        const tx = new TransactionBlock();
        const [upgradeCap] = tx.publish({
            modules,
            dependencies,
        });
        tx.transferObjects([upgradeCap], tx.pure(account));
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

        const packageId = ((result.objectChanges?.filter(
            (a) => a.type === 'published',
        ) as SuiObjectChangePublished[]) ?? [])[0].packageId.replace(/^(0x)(0+)/, '0x') as string;
        let GameListId;
        let RPSCapId;
        let TreasuryCapId;
        let WhiteListedTokensId;
        let CoinMetadataId;
        let GameInfoId;
        // console.log(`packaged ID : ${packageId}`);
        await sleep(10000);

        if (!digest_) {
            console.log("Digest is not available");
            return { packageId, GameListId, RPSCapId };
        }

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

        for (let i = 0; i < output.length; i++) {
            const item = output[i];
            if (await item.type === 'created') {
                if (await item.objectType === `${packageId}::rps::GameList`) {
                    GameListId = String(item.objectId);
                }
                if (await item.objectType === `${packageId}::rps::RPSGameCap`) {
                    RPSCapId = String(item.objectId);
                }
                if (await item.objectType == `0x2::coin::TreasuryCap<${packageId}::rps::RPS>`) {
                    TreasuryCapId = String(item.objectId);
                }
                if (await item.objectType == `${packageId}::rps::WhiteListedTokens`) {
                    WhiteListedTokensId = String(item.objectId);
                }
                if (await item.objectType == `0x2::coin::CoinMetadata<${packageId}::rps::RPS>`) {
                    CoinMetadataId = String(item.objectId);
                }
                if (await item.objectType == `${packageId}::rps::GameInfo`) {
                    GameInfoId = String(item.objectId);
                }
            }
        }
        return { packageId, GameListId, RPSCapId, TreasuryCapId, WhiteListedTokensId, CoinMetadataId, GameInfoId };
    } catch (error) {
        // Handle potential errors if the promise rejects
        console.error(error);
        return { packageId: '', GameListId: '', RPSCapId: '', TreasuryCapId: '', WhiteListedTokensId: '', CoinMetadataId: '', GameInfoId: '' };
    }
};

// Call the async function and handle the result.
getPackageId()
    .then((result) => {
        console.log(result);
    })
    .catch((error) => {
        console.error(error);
    });

export default getPackageId;