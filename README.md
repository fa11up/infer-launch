# infer-launch

Contracts for the INFER custom-token launch.

| contract | what it is |
|---|---|
| `InferToken` | the token: fixed supply of 1,000,000,000, minted once to the launch factory |
| `LegacyRedeemer` | burn MIYA or MXXN for INFER at fixed rates for one year; large redemptions vest |
| `SeasonVault` | the points allocation, paid in seasons the governor opens; roots attested by a swarm panel (`SeasonAttestation`) |
| `FounderStream` | the founder allocation, linear over 12 months with a 30-day cliff |
| `StakedInfer` | sINFER, an ERC-4626 vault over INFER |
| `InferDripper` | streams INFER bought with protocol revenue into sINFER |

The launch remainder goes to a `GenesisSplitter` (in `lib/genesis-splitter`), deployed before the launch, which
pays each contract above its `genesisAllocation()`.

```
forge build
forge test                                  # unit tests
forge test --fork-url <mainnet RPC>         # also: the launch through the live ProjectFactory, MIYA and MXXN
```
