### Product Backlog Priority Matrix

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%
quadrantChart
    title Product Backlog Priority Matrix
    x-axis Low Effort --> High Effort
    y-axis Low Impact --> High Impact
    quadrant-1 Plan Carefully
    quadrant-2 Do First
    quadrant-3 Quick Wins Done
    quadrant-4 Deprioritize
    SSO login: [0.25, 0.92]
    Dark mode: [0.35, 0.38]
    API rate limiting: [0.55, 0.88]
    Native mobile app: [0.92, 0.75]
    Full-text search: [0.68, 0.62]
    Password reset flow: [0.18, 0.82]
    Admin analytics dashboard: [0.78, 0.55]
    Webhook support: [0.42, 0.70]
    CSV export: [0.22, 0.45]
```

Quadrant chart mapping 9 product backlog items by effort vs. impact. SSO login and Password reset flow land in "Do First" (high impact, low effort). Native mobile app and Admin analytics dashboard fall under "Plan Carefully" (high impact, high effort). No custom styling applied — quadrant charts are themed via the init block only.
