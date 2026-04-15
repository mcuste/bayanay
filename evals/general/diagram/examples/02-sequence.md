### REST API File Upload

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

sequenceDiagram
    participant B as Browser
    participant GW as API Gateway
    participant Auth as Auth Service
    participant S3 as S3
    participant DB as PostgreSQL
    participant MQ as Message Queue
    participant NS as Notification Service

    B->>GW: POST /upload (multipart)
    activate GW

    GW->>Auth: validate JWT
    activate Auth
    Auth-->>GW: valid / invalid
    deactivate Auth

    alt invalid token
        rect rgb(248,187,208)
            GW-->>B: 401 Unauthorized
        end
    else valid token
        rect rgb(200,230,201)
            GW->>S3: stream file
            activate S3
            S3-->>GW: storage URL
            deactivate S3

            GW->>DB: save metadata<br/>(name, size, S3 URL, uploader ID)
            activate DB
            DB-->>GW: OK
            deactivate DB

            GW->>MQ: publish "file.uploaded"
            activate MQ
            MQ->>NS: trigger event
            deactivate MQ
            activate NS
            NS->>NS: send webhook to<br/>callback URL
            deactivate NS

            GW-->>B: 200 OK + file URL
        end
    end

    deactivate GW
```

Sequence diagram showing the full file upload flow through an API Gateway. The `alt` block splits the authentication outcome into an error path (pink) returning 401 and a success path (green) covering S3 upload, metadata persistence, event publishing, and webhook notification before returning 200 with the file URL.
