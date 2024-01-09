import { SuiObjectChangePublished } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import getExecStuff from './execstuff';

const { execSync } = require('child_process');

function sleep(ms: number): Promise<void> {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    });
}

const GetPackageId = async () => {
    try {
        const { keypair, client } = getExecStuff();
        const account = "0x821febff0631744c231a0f696f62b72576f2634b2ade78c74ff20f1df97fc9bf";
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
            if (item.type === 'created') {
                if (item.objectType === `${packageId}::rps::GameList`) {
                    GameListId = String(item.objectId);
                }
                if (item.objectType === `${packageId}::rps::RPSCap`){
                    RPSCapId = String(item.objectId);
                }
            }
        }
        return { packageId, GameListId, RPSCapId };
    } catch (error) {
        // Handle potential errors if the promise rejects
        console.error(error);
        return { packageId: '', GameListId: '', RPSCapId: ''};
    }
};

// Call the async function and handle the result.
GetPackageId()
    .then((result) => {
        console.log(result);
    })
    .catch((error) => {
        console.error(error);
    });

export default GetPackageId;
