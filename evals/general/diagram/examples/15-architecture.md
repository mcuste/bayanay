### AWS Cloud Architecture

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

flowchart TD
    classDef ext fill:#E1BEE7,stroke:#6A1B9A,color:#212121

    client([Client Browser]):::ext --> cf[CloudFront CDN]
    cf -->|static assets| s3_static[(S3 Static Assets)]
    cf -->|api requests| alb[Application<br/>Load Balancer]

    subgraph vpc [VPC]
        alb --> ecs[ECS Containers<br/>Node.js API]
        ecs --> rds[(RDS Aurora<br/>PostgreSQL)]
        ecs --> redis[(ElastiCache<br/>Redis)]
        ecs -->|messages| sqs[SQS Queue]
        sqs -->|triggers| lambda[Lambda<br/>Async Processing]
        lambda -->|read/write| s3_files[(S3 File<br/>Processing)]
    end
```

Flowchart TD chosen over `architecture-beta` because the diagram has connected nodes with a VPC boundary -- the skill guidelines specify `flowchart` + `subgraph` for this pattern. Client browser styled as external (purple). VPC boundary groups ECS, RDS, ElastiCache, SQS, and Lambda. Storage nodes use cylinder shape. Edge labels kept short, omitted where self-evident.
