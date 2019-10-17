# Monetha: Decentralized Reputation Framework [![Build Status][1]][2]

[1]: https://travis-ci.org/monetha/verifiable-data-layer-contracts.svg?branch=master
[2]: https://travis-ci.org/monetha/verifiable-data-layer-contracts

# Reputation Layer

* [Reputation Layer Contracts design](#reputation-layer-contracts-design)
* Reputation Passport
    * [Passport logic](#passport-logic)
    * [Passport logic registry](#passport-logic-registry)
    * [Passport](#passport)
* [Passport factory](#passport-factory)
* [Facts provider registry](#facts-provider-registry)

## Reputation Layer contracts design

The main idea behind our implementation is that the reputation passport is data storage owned by users, but all passports share the same 
contract that handles the logic. All the methods of the passport logic contract are executed in 
the context of the data of the passport contract through which they were called.

Currently implemented model: 

                              ╔═══════════════════╗
          deploys             ║                   ║
    ┌─────passport────────────║  PassportFactory  ║
    │                         ║                   ║
    │                         ╚═══════════════════╝
    │                                   │
    │                           uses registry to
    │                          bind it to passport
    │                                   │
    │                                   ▼
    │                   ╔═══════════════════════════════╗
    │                   ║     PassportLogicRegistry     ║
    │                   ║  ┌─────────────────────────┐  ║
    │                   ║  │    versions mapping     │──╬────────────────────┬─────────────────────┐
    │                   ║  └─────────────────────────┘  ║                    │                     │
    │                   ║  ┌─────────────────────────┐  ║                  v0.1                  v0.2
    │          ┌────────╬─▶│ current passport logic  │──╬───┐                │                     │
    │          │        ║  └─────────────────────────┘  ║   │                │                     │
    │          │        ╚═══════════════════════════════╝   │      ╔═══════════════════╗ ╔═══════════════════╗
    │    gets current                                       │      ║                   ║ ║                   ║
    │      passport                                         └──────║   PassportLogic   ║ ║  PassportLogicV2  ║
    │        logic                                                 ║                   ║ ║                   ║
    │          │                                                   ╚═══════════════════╝ ╚═══════════════════╝
    │          │                                                             ▲
    │  ╔═══════╩══════╗                                                      │
    │  ║   Passport   ║                   delegate call                      │
    ├─▶║  (owner 1)   ║─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
    │  ╚═══════╦══════╝                                                      │
    │          │                                                             │
    │          │                                                             │
    │  ╔═══════╩══════╗                                                      │
    │  ║   Passport   ║                   delegate call                      │
    ├─▶║  (owner 2)   ║─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
    │  ╚═══════╦══════╝                                                      │
    │          │
    │         ...                                                            │
    │          │
    │  ╔══════════════╗                                                      │
    │  ║   Passport   ║                   delegate call
    └─▶║  (owner N)   ║─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
       ╚══════════════╝

### Passport logic

[`PassportLogic`](contracts/PassportLogic.sol) contract defines upgradable behavior of `Passport` contract, assuming that 
each version will follow the storage structure of the previous one, but having the chance to add new behaviour and/or state variables. 
Current `PassportLogic` implementation provides generic key-value storage structure. This is an initial set of mappings for 
each type variable which could be accessed, modified or deleted by fact providers. Information can be saved to storage or as transaction data.
Data can be accessed by any person, but the facts can be modified or deleted only by the fact provider who has provided them. Currently supported set of methods is defined in 
[`IPassportLogic`](contracts/IPassportLogic.sol).

Once the `PassportLogic` contract is created, it is registered in `PassportLogicRegistry` so that its logic 
could be reused later in all the passports that use this registry. Passport owner might decide to use different registry if the logic which is maintained and developed by Monetha does not meet owner's requirementes.

### Passport logic registry
  
[`PassportLogicRegistry`](contracts/PassportLogicRegistry.sol) contract contains versioned registry of passport logic.
It allows to add new versions of passport logic and set one of the available versions as current, which 
will be used by all the passports. The registry simplifies the upgrade of the passport logic, leaving it be transparent,
and at the same time it does not restrict the passport owner in choosing a registry of passport logic.

### Passport

[`Passport`](contracts/Passport.sol) is a contract owned by the passport owner. It behaves like proxy that delegates
calls (using `delegatecall`) to current passport logic implementation which is currently set in the `PassportLogicRegistry`.
Given the passport uses `delegatecall` to resolve the requested behaviors, the upgradable passport logic contract's state
will be stored in the passport contract itself.

Passport owner is allowed to change the registry of passport logic, destroy passport or transfer ownership to the new 
owner (the ownership needs to be claimed).

### Passport factory

[`PassportFactory`](contracts/PassportFactory.sol) contract allows anyone to deploy a new Reputation passport. To deploy a reputation passport one 
should call the passport factory's `createPassport()` method. During this call the passport factory deploys a new passport 
and binds it to the existing `PassportLogicRegistry` contract. It also emits `PassportCreated(address indexed passport, address indexed owner)`
event that allows you to get the address of the deployed passport.

After the passport contract is deployed, the same account who called the passport factory's `createPassport()` method should 
additionally call the passport's `claimOwnership()` method to finalize the ownership transfer of the passport.

### Facts provider registry

[`FactProviderRegistry`](contracts/FactProviderRegistry.sol) contract behaves like a naming system for the known fact providers.
It associates various information (like name, passport address, website) with the fact provider address. `factProviders` mapping 
should be used to get this information by the facts provider address:

```solidity
    struct FactProviderInfo {
        bool initialized;
        string name;
        address reputation_passport;
        string website;
    }

    mapping(address => FactProviderInfo) public factProviders;
```
