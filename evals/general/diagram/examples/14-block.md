### Microservices Architecture

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

flowchart LR
    classDef store  fill:#C8E6C9,stroke:#2E7D32,color:#212121
    classDef cache  fill:#FFF9C4,stroke:#F9A825,color:#212121
    classDef broker fill:#E1BEE7,stroke:#6A1B9A,color:#212121

    subgraph leftCol["Left"]
        gw["API Gateway"]
    end

    subgraph midCol["Services"]
        auth["Auth Service"]
        user["User Service"]
        order["Order Service"]
        payment["Payment Service"]
    end

    subgraph rightCol["Data Layer"]
        pg[("PostgreSQL")]:::store
        redis[("Redis Cache")]:::cache
        mq[["Message Queue<br/>(RabbitMQ)"]]:::broker
    end

    gw --> auth
    gw --> user
    gw --> order
    gw --> payment

    auth  --> pg
    user  --> pg
    order --> pg

    order   --> redis
    payment --> redis

    order   --> mq
    payment --> mq
```

Uses `flowchart LR` with `subgraph` columns instead of `block-beta` — the diagram has connections between nodes, so block-beta's poor edge routing would cause arrows to pass through other nodes. Semantic colors: green for PostgreSQL (persistent storage), yellow for Redis Cache (ephemeral), purple for RabbitMQ (external broker).
