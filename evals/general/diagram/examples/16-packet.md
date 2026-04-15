### Application Protocol Header

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%
packet-beta
    0-3: "Version"
    4-7: "Message Type"
    8-15: "Flags"
    16-31: "Total Length"
    32-63: "Correlation ID"
    64-79: "Source Node ID"
    80-95: "Destination Node ID"
    96-127: "Sequence Number"
    128-159: "Timestamp"
    160-191: "Payload Checksum"
```

Binary layout of a custom application protocol header. Each row is 32 bits wide. Fields are packed contiguously starting at bit 0 through bit 191 (24 bytes total). The first row contains four fields (Version, Message Type, Flags, Total Length), while subsequent rows hold one or two fields each depending on their bit width.

> **Note:** `packet-beta` requires Mermaid >= 11.0.0. Renderers on 10.x will show a syntax error.
