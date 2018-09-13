# Protocol contracts

                     ╔═══════════════════════════════╗
                     ║     PassportLogicRegistry     ║
                     ║  ┌─────────────────────────┐  ║
                     ║  │    versions mapping     │──╬────────────────────┬─────────────────────┐
                     ║  └─────────────────────────┘  ║                    │                     │
                     ║  ┌─────────────────────────┐  ║                  v0.1                  v0.2
           ┌─────────╬─▶│ current passport logic  │──╬───┐                │                     │
           │         ║  └─────────────────────────┘  ║   │                ▼                     ▼
           │         ╚═══════════════════════════════╝   │      ╔═══════════════════╗ ╔═══════════════════╗
     gets current                                        │      ║                   ║ ║                   ║
       passport                                          └─────▶║   PassportLogic   ║ ║  PassportLogicV2  ║
         logic                                                  ║                   ║ ║                   ║
           │                                                    ╚═══════════════════╝ ╚═══════════════════╝
           │                                                              ▲
    ╔═════════════╗
    ║             ║                    delegate call                      │
    ║  Passport   ║─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
    ║             ║
    ╚═════════════╝
