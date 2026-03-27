# Serde

- [serde-deny-unknown] ALWAYS use `#[serde(deny_unknown_fields)]` on config and request input types
- [serde-transparent] ALWAYS use `#[serde(transparent)]` on single-field newtypes
- [serde-enum-repr] ALWAYS choose enum representation explicitly: `#[serde(tag = "type")]` for most APIs, `#[serde(tag = "type", content = "data")]` for heterogeneous content
- [serde-rename-all] ALWAYS use `#[serde(rename_all = "camelCase")]` or appropriate convention on public API types
- [serde-roundtrip-test] ALWAYS test serde roundtrips for types with custom serde attributes
- [serde-no-untagged] NEVER use `#[serde(untagged)]` unless no alternative exists
- [serde-field-default] ALWAYS prefer field-level `#[serde(default = "fn")]` over struct-level `#[serde(default)]` when only some fields have defaults
- [serde-skip-none] ALWAYS use `#[serde(skip_serializing_if = "Option::is_none")]` on `Option` fields in API response types
- [serde-try-from] ALWAYS prefer `#[serde(try_from = "String")]` over custom `Deserialize` impl for validated newtypes
- [serde-no-flatten-deny] NEVER combine `#[serde(flatten)]` with `#[serde(deny_unknown_fields)]`
- [serde-dto-split] ALWAYS separate wire/serialization types (DTOs) from domain types when serde conflicts with domain invariants
