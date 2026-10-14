# HOOKSHIFT — BNB Chain testnet MVP

Blue-and-white landing page, local simulator, BNB Chain **testnet** treasury console, Solidity treasury contract and Hardhat tests.

## Run locally

Requires Node.js 20+.

```bash
npm install
npm test
npm run compile
```

Deploy testnet contract only after reviewing the code:

```bash
cp .env.example .env
# Set DEPLOYER_PRIVATE_KEY to a disposable TESTNET-only key, never a production key.
npm run deploy:testnet
```

The script prints the deployed contract address. Open `dashboard.html` in the deployed site, connect an EVM wallet to chain ID 97 and enter that address.

## Vercel

Import this GitHub repository in Vercel. Framework preset **Other**, root directory `/`, no build command. The HTML frontend is static. Solidity and tests are source files only; Vercel does not deploy smart contracts.

## Scope and security

- BNB Chain testnet (chain ID 97), not mainnet.
- Owner-only allowlist, proposal creation, cancellation and execution.
- At least one-hour timelock; daily spending limit capped at 30% by constructor; emergency pause.
- Wallet-based console, test BNB deposits, owner transactions and read-only treasury stats.
- Strategy simulator is local arithmetic, **not an AI trading agent**.
- No token creation, Four.meme hooks, live AI automation, swaps, oracle feeds or price-impact enforcement.
- Contracts are **unaudited**. Do not deploy to mainnet or use with real funds.
- Keep private keys exclusively in local environment variables. Never commit `.env`.
- For production: audit, multisig owner, governance, execution guards, integration tests, monitored keeper, and verified integrations are required.
