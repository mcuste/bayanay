### Microservices Architecture

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

flowchart LR
    classDef store fill:#C8E6C9,stroke:#2E7D32,color:#212121
    classDef queue fill:#E1BEE7,stroke:#6A1B9A,color:#212121

    subgraph gateway [API Gateway]
        gw([API Gateway])
    end

    subgraph services [Services]
        auth[Auth Service]
        user[User Service]
        order[Order Service]
        pay[Payment Service]
    end

    subgraph data [Data Stores]
        pg[(PostgreSQL)]:::store
        redis[(Redis Cache)]:::store
        mq[[Message Queue<br/>RabbitMQ]]:::queue
    end

    gw --> auth
    gw --> user
    gw --> order
    gw --> pay

    auth --> pg
    user --> pg
    order --> pg

    order --> redis
    pay --> redis

    order --> mq
    pay --> mq
```

Uses `flowchart LR` with `subgraph` instead of `block-beta` since the fixture requires connections between nodes (block-beta arrows pass through nodes). Three subgraphs represent the columns: API Gateway on the left, four stacked services in the middle, and data stores on the right. PostgreSQL, Redis, and RabbitMQ use cylinder and subroutine shapes. Data stores colored green, message queue purple (external/async system).
