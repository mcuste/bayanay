### E-Commerce Order Lifecycle

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

stateDiagram-v2
    classDef pending fill:#FFF9C4,stroke:#F9A825,color:#212121
    classDef ok fill:#C8E6C9,stroke:#2E7D32,color:#212121
    classDef err fill:#F8BBD0,stroke:#AD1457,color:#212121
    classDef ext fill:#E1BEE7,stroke:#6A1B9A,color:#212121

    [*] --> Draft
    Draft --> PendingPayment : submit order
    PendingPayment --> Confirmed : payment succeeds
    PendingPayment --> Cancelled : payment fails / timeout 30m
    Confirmed --> Processing : warehouse accepts
    Processing --> Shipped : tracking assigned
    Shipped --> Delivered : carrier confirms
    Delivered --> Refunded : refund approved<br/>within 30 days
    Delivered --> [*]
    Cancelled --> [*]
    Refunded --> [*]

    Draft --> Cancelled : customer request
    Confirmed --> Cancelled : customer request
    Processing --> Cancelled : customer request

    state "Pending Payment" as PendingPayment

    PendingPayment:::pending
    Delivered:::ok
    Cancelled:::err
    Refunded:::ext
```

Order flows from Draft through payment, processing, and shipping to Delivered. Cancellation is possible from any state before Shipped (Draft, Pending Payment, Confirmed, Processing) via customer request, plus automatic cancellation on payment failure/timeout. Refunds available within 30 days of delivery. Terminal states: Delivered, Cancelled, Refunded.
