### Growth Metrics H1 2025 — Monthly Active Users

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%
xychart-beta
    title "Growth Metrics H1 2025 — MAU"
    x-axis [Jan, Feb, Mar, Apr, May, Jun]
    y-axis "Monthly Active Users" 0 --> 22000
    bar [12400, 13200, 15800, 14900, 17200, 19500]
```

### Growth Metrics H1 2025 — Monthly Recurring Revenue

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%
xychart-beta
    title "Growth Metrics H1 2025 — MRR ($K)"
    x-axis [Jan, Feb, Mar, Apr, May, Jun]
    y-axis "MRR ($K)" 0 --> 160
    line [82, 91, 108, 103, 124, 143]
```

Split into two charts because `xychart-beta` supports only a single y-axis. MAU (12K-19.5K) and MRR ($82K-$143K) differ in scale by an order of magnitude — combining them on one axis would flatten the smaller series. MAU shown as bars to emphasize monthly volume, MRR as a line to highlight the revenue trend. April dip visible in both metrics.

> **Note:** `xychart-beta` requires Mermaid >= 10.5.0. Renderers on 10.2.x will show a syntax error.
