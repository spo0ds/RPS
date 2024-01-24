## RPS Game: A Fun and Educational Project for Sui Developers

This repository showcases a simple Rock-Paper-Scissors game built on the Sui blockchain. It serves as a valuable learning resource for developers interested in exploring the possibilities of building within the Sui ecosystem.

Features:

For Players:

- Manage your friendlist: Add and connect with fellow Rock-Paper-Scissors enthusiasts.
- Challenge the world: Issue playful duels to anyone, whether they're on your friendlist or not.
- Whitelisted competition: Use designated tokens for secure and transparent gameplay.
- Claim your rewards: Collect your winnings after each exciting round.

For Admins:

- Token control: Define which tokens are eligible for game participation.
- Game management: Pause and resume games as needed to ensure smooth play.
- Fee adjustments: Adapt the protocol fee for optimal game economics.
- Token minting: Generate custom tokens for specific addresses.
- Winner selection: Choose the champion and distribute the winning prize accurately.


## Getting Started:

- Deploy the contract using the provided command.

```ts
ts-node utils/setup.ts
```

- Update the package identifiers based on the deployment output.

- Whitelist the necessary tokens ("rps" and "sui") from the admin address.

```ts
ts-node src/updateWhitelistedTokens.ts
```

- Mint custom tokens to target addresses, again using the admin account.

```ts
ts-node src/mintToken.ts
```

- Create a friendlist object to manage your network of game buddies.

```ts
ts-node src/createFriendList.ts
```

- (Optional) Add friends if you prefer playing within your circle.

```ts
ts-node src/addFriend.ts
```

- Challenge your opponents by creating an RPS game.

```ts
ts-node src/createRpsGame.ts
```

- Accept challenges and play from any other address.

```ts
ts-node src/playRpsGame.ts
```

- When both players have chosen their moves, the admin can determine the winner.

```ts
ts-node src/selectWinner
```

- The victor receives the designated prize money (unless it's a tie).

## Beyond the Game:

This project not only offers a fun way to interact with the Sui blockchain, but also presents a practical learning tool for developers. By exploring the code and functionalities, you can gain valuable insights into building your own applications within the Sui ecosystem.

### Thank you for your interest in this project! Feel free to explore and build upon it. Happy gaming and happy coding!
