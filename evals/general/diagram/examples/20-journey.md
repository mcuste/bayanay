### SaaS Subscription Purchase Journey

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%
journey
    title SaaS Subscription Purchase Journey
    section Discovery
        Find product via Google search: 3: Prospect
        Read landing page: 4: Prospect
        Watch demo video: 4: Prospect
        Check pricing page: 3: Prospect
    section Trial
        Sign up for free trial: 4: User
        Receive onboarding email: 3: User
        Complete setup wizard: 3: User
        First meaningful feature use: 5: User
    section Evaluation
        Hit trial limitation: 2: User
        Compare plan tiers: 3: User
        Talk to sales rep: 4: User, Sales
    section Conversion
        Enter payment details: 2: User
        Confirm subscription: 5: User
        Receive confirmation email: 4: User
    section Retention
        Weekly active usage: 5: User
        Share with teammate: 5: User, Colleague
        Annual renewal: 4: User
```

Journey diagram mapping the full SaaS purchase lifecycle across five sections: Discovery, Trial, Evaluation, Conversion, and Retention. Satisfaction scores (1-5) reflect typical user sentiment at each step — pain points surface at trial limitations (2) and payment entry (2), while feature engagement and subscription confirmation peak at 5. Multiple actors (Prospect, User, Sales, Colleague) show handoffs across the journey.
