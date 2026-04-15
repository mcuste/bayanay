### Team Release Process — Git Workflow

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

gitGraph
    commit id: "init"
    branch develop
    checkout develop
    commit id: "dev-setup"
    branch feature/oauth2
    checkout feature/oauth2
    commit id: "oauth2-impl"
    commit id: "oauth2-tests"
    checkout develop
    branch feature/stripe-payments
    checkout feature/stripe-payments
    commit id: "stripe-init"
    commit id: "stripe-checkout"
    checkout develop
    merge feature/oauth2 id: "merge-oauth2"
    merge feature/stripe-payments id: "merge-stripe"
    checkout main
    merge develop id: "release-2.0" tag: "v2.0.0"
    branch hotfix
    checkout hotfix
    commit id: "fix-billing-calc"
    checkout main
    merge hotfix id: "hotfix-merge" tag: "v2.0.1"
    checkout develop
    merge hotfix id: "hotfix-to-dev"
    branch feature/dark-mode
    checkout feature/dark-mode
    commit id: "dark-mode-init"
```

Diagram type: `gitGraph` — direct match for git branching workflow.

Covers the full release process: two feature branches off develop (oauth2 merged first, then stripe-payments), release merge to main tagged v2.0.0, hotfix branch from main with billing fix merged back to both main (tagged v2.0.1) and develop, and new feature/dark-mode branch with initial commit. No semantic coloring applied — gitGraph relies entirely on the theme init block for styling.
