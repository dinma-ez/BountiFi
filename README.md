# BountiFi

BountiFi is a blockchain-based scavenger hunt smart contract that introduces progressive puzzles, clues, and rewards on-chain. Players register, pay an entry fee, and solve puzzles in sequential stages. Each solved stage distributes prizes to winners, creating an engaging mix of gaming, cryptography, and decentralized incentives.

## Key Features

### Hunt Management

* **Admin-Controlled Initialization**: The administrator can activate or reset the hunt.
* **Stage Creation**: Each stage includes a clue, solution hash, unlock block height, prize, and solved status.
* **Dynamic Prize Pool**: The total prize pool increases as new stages with prizes are added.

### Player System

* **Registration**: Players pay an entry fee in STX to participate.
* **Progress Tracking**: The contract tracks solved stages, current stage, and total progress for each player.
* **Solution Submission**: Players submit solutions as SHA256 hashes to verify correctness.

### Gameplay

* **Stage Unlocking**: Each stage can be time-locked until a certain block height is reached.
* **Fair Rewards**: The first correct solver receives the prize for that stage.
* **Winner Records**: Each stage stores up to 10 winners, including timestamps of when they solved it.

### Prize Distribution

* **STX Transfers**: When a player solves a stage, their prize is transferred automatically from the contract’s prize pool.
* **Admin Prize Funding**: Stage creation with prizes increases the prize pool balance.

## Data Structures

* **hunt-stages**: Stores stage information (clue, solution hash, unlock height, prize, solved status).
* **player-progress**: Tracks each player’s solved stages, current stage, and overall performance.
* **stage-solutions**: Records player attempts and successful solve times.
* **stage-winners**: Keeps a capped list of stage winners with timestamps.

## Error Codes

* `ERR-NOT-AUTHORIZED (u1)`: Unauthorized access.
* `ERR-HUNT-NOT-ACTIVE (u2)`: Hunt not active.
* `ERR-INVALID-STAGE (u3)`: Invalid stage reference.
* `ERR-ALREADY-SOLVED (u4)`: Stage already solved.
* `ERR-WRONG-SOLUTION (u5)`: Submitted solution is incorrect.
* `ERR-TIME-LOCKED (u6)`: Stage cannot be accessed before unlock height.
* `ERR-INSUFFICIENT-PAYMENT (u7)`: Entry fee not met.

## Read-Only Functions

* **get-current-clue(stage-id)**: Retrieves the clue if the stage is unlocked.
* **get-player-status(player)**: Returns progress and solved stages for a player.
* **get-stage-winners(stage-id)**: Lists winners for a specific stage.
* **get-hunt-stats**: Returns current hunt status, stage index, prize pool, and entry fee.

## How It Works

1. **Admin initializes the hunt** and adds puzzle stages with locked prizes.
2. **Players register** by paying the entry fee.
3. **Stages unlock** at specific block heights, revealing clues.
4. **Players submit hashed solutions** to verify correctness.
5. **Correct solvers** receive rewards and are recorded as stage winners.
6. **Hunt progresses** until all stages are solved.