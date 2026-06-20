# Shaka Love Demo

A Solidity demo and technical archive built around a fictional "heartbeat synchronization" concept. This repository preserves a creative smart contract (`ShakaLoveDemo.sol`) and related exhibit materials as a non-commercial technical artifact.

This is an exhibit, not a product. The `LOVE` token defined here exists only to demonstrate contract structure and is not connected to any real value, sale, or service.

---

## Safety Notice

- This code is **not audited**.
- It is **not intended for production use**.
- It is **not intended for mainnet deployment**.
- No deployment scripts are included, by design.
- The `LOVE` token has **no promised value, utility, or redemption**.
- Do **not** use this code with real private keys, real funds, or production oracle systems.

Treat everything here as reference material for reading and compiling only.

---

## What This Is / What This Is Not

**What this is**

- A demo smart contract preserved as a memorial / technical exhibit.
- An illustration of patterns such as EIP-712 typed attestations, oracle-signed verification, cooldowns, and daily mint limits.
- A compilable Hardhat setup for inspecting and building the contract locally.
- Non-commercial archive page materials describing the concept.

**What this is not**

- Not a financial product.
- Not an investment, security, or payment method.
- Not a token sale or fundraising mechanism.
- Not financial, legal, or investment advice.
- Not production-ready or audited software.

---

## Repository Structure

```txt
.
|-- contracts/
|   `-- ShakaLoveDemo.sol      # Demo-only ERC20 + attestation contract
|-- hardhat.config.js          # Hardhat configuration for compile checks
|-- package.json
|-- package-lock.json
|-- README.md
`-- notes-and-exhibit-files/   # Local notes and exhibit materials, not compiled
```

The repository ships with a compilable Hardhat configuration. **Deployment scripts are intentionally omitted** to discourage running this on any live network.

---

## Install and Compile

Requirements: Node.js LTS and npm.

```bash
npm install
npx hardhat compile
```

No network configuration, deploy task, or live-chain interaction is provided.

---

## No Financial Value / No Sale / No Investment Advice

The `LOVE` token in this repository is a demonstration artifact only.

- It is **not** for sale and has **no price**.
- It carries **no financial value** and makes **no promise** of value, yield, or redemption.
- Nothing here constitutes an offer, solicitation, or **investment advice**.
- Any resemblance to a real financial instrument is incidental to the demo concept.

Do not interpret this project as an opportunity to buy, sell, trade, or invest.

---

## Do Not Use Real Keys or Funds

Because this is a demo and exhibit:

- Do **not** import or paste real private keys.
- Do **not** send real funds to any address related to this code.
- Do **not** point it at a production oracle or signing service.

Use only throwaway, local development environments if you choose to experiment.

---

## License

The contract is published under the **MIT License** (see the SPDX identifier in `ShakaLoveDemo.sol`). If this repository is published on GitHub, adding a root `LICENSE` file with the MIT License text is recommended for clarity.

The MIT License covers code reuse only. It grants no rights, value, financial claim, redemption claim, or guarantee regarding the `LOVE` token concept itself.
