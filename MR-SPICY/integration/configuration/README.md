# `configuration/`

Build/runtime configuration for an integration lives here, e.g.:

* `spicy-ui.plist` / `.json` — which tiles a host exposes, default language, default appearance
* per-environment overrides (debug / staging / release)
* CI configuration that runs the MR. SPICY validation gates inside a host's pipeline

Configuration must only describe presentation. It must never carry credentials, licence keys,
entitlement claims or anything that asserts authorisation the host has not actually obtained.

Currently empty: no authorised host integration exists in this repository.
