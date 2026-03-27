### AWS Cloud Architecture

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

flowchart LR
    classDef ext fill:#E1BEE7,stroke:#6A1B9A,color:#212121
    classDef storage fill:#FFF9C4,stroke:#F9A825,color:#212121
    classDef async fill:#C8E6C9,stroke:#2E7D32,color:#212121

    client([Browser Client]):::ext
    cf[CloudFront CDN]
    s3assets[(S3 Static Assets)]:::storage

    client --> cf
    cf -->|"static assets"| s3assets
    cf -->|"API requests"| alb

    subgraph vpc[VPC]
        alb[Application Load Balancer]
        ecs[ECS Node.js API]
        rds[(RDS Aurora PostgreSQL)]:::storage
        redis[(ElastiCache Redis)]:::storage
        sqs[[SQS Queue]]:::async
        lambda[Lambda Functions]:::async
    end

    s3proc[(S3 File Storage)]:::storage

    alb --> ecs
    ecs --> rds
    ecs --> redis
    ecs -->|"enqueue"| sqs
    sqs -->|"triggers"| lambda
    lambda --> s3proc
```

Uses `flowchart LR` with `subgraph` for the VPC boundary instead of `architecture-beta` — the diagram has many connections and several labels with special characters (Node.js, RDS Aurora), which `architecture-beta` doesn't support. Color coding: purple = external client, yellow = storage services, green = async/messaging components.
