# `adapters/`

One directory per **authorised** host application + version:

```
adapters/
└── <host-bundle-id>-<version>/
    ├── SpicyAdapter.swift        conforms to SpicyOverlayDataSource / SpicyOverlayDelegate
    ├── notes.md                  integration points used, constraints, verified behaviour
    └── compatibility.md          measured compatibility for this pairing
```

Rules:

* The adapter is the **only** host-version-specific code. Component internals never fork per host.
* An adapter may read host state; it may never fabricate it.
* A new host version gets a **new** adapter directory. Old ones stay for rollback.

Currently empty: no authorised host exists in this repository. The supplied IPA is a third-party
commercial application and is out of scope — see `../integration-notes/README.md`.
