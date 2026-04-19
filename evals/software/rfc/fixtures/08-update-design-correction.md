update docs/rfc/RFC-001-api-versioning.md

We need to change the versioning approach. After prototyping URL-path versioning we found that our API gateway (Kong) makes header-based versioning easy with built-in plugins, and our CDN (Cloudflare) now supports Vary header caching properly. The original rejection reasons for header-based versioning no longer apply. Switch the proposed solution to header-based versioning.
