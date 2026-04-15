### Sprint Kanban Board

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%
kanban
    Backlog
        Write OpenAPI Documentation
        Add Dark Mode Toggle
        Fix Pagination on User List Page
        Implement CSV Export
    In Progress
        OAuth2 Login Integration
        Database Schema Migration for v2
        Rate Limiting Middleware
    In Review
        User Profile Edit Page
        Webhook Delivery System
    Testing
        Email Notification Templates
    Done
        CI/CD Pipeline Setup
        Fix Session Timeout Bug
        Password Strength Indicator
```

All 13 tasks placed across 5 columns matching the fixture. Kanban type chosen since the request explicitly asks for a board-style task tracker. No custom styling applied — kanban does not support `classDef`. Theme init block handles colors.

> **Note:** `kanban` requires Mermaid >= 11.4.0. Renderers on 10.x will show a syntax error.
