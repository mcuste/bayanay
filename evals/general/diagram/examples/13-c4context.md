### DataLens SaaS Analytics Platform — C4 Context

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

C4Context
    title DataLens — System Context Diagram
    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")

    Person(analyst, "Data Analyst", "Builds dashboards and runs queries")
    Person(exec, "Business Executive", "Views dashboards and reports")
    Person(apidev, "API Developer", "Integrates via REST API")

    System(datalens, "DataLens", "SaaS analytics platform for dashboards, queries, and scheduled reports")

    System_Ext(salesforce, "Salesforce CRM", "CRM")
    System_Ext(snowflake, "Snowflake", "Data warehouse")
    System_Ext(sendgrid, "SendGrid", "Email delivery")
    System_Ext(auth0, "Auth0", "SSO")
    System_Ext(stripe, "Stripe", "Billing")

    Rel(analyst, datalens, "Uses")
    Rel(exec, datalens, "Views")
    Rel(apidev, datalens, "REST API")

    Rel_D(datalens, salesforce, "REST")
    Rel_D(datalens, snowflake, "JDBC")
    Rel_D(datalens, sendgrid, "SMTP")
    Rel_D(datalens, auth0, "OAuth 2.0")
    Rel_D(datalens, stripe, "REST")
```

Three user personas (Data Analyst, Business Executive, API Developer) interact with the central DataLens system. Five external systems: Salesforce CRM (REST), Snowflake (JDBC), SendGrid (SMTP), Auth0 (OAuth 2.0), Stripe (REST). Arrow crossings are a known C4 renderer limitation with hub-and-spoke topologies.
