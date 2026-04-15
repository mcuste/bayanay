### User Authentication Flow

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

flowchart TD
    classDef ok fill:#C8E6C9,stroke:#2E7D32,color:#212121
    classDef err fill:#F8BBD0,stroke:#AD1457,color:#212121
    classDef warn fill:#FFF9C4,stroke:#F9A825,color:#212121
    classDef ext fill:#E1BEE7,stroke:#6A1B9A,color:#212121

    start([Enter Email & Password]) --> exists{Account Exists?}
    exists -->|no| notfound[Account Not Found]:::err
    exists -->|yes| validate{Valid Password?}
    validate -->|yes| mfa{MFA Enabled?}
    validate -->|no| inc[Increment Failed<br/>Attempt Counter]:::warn
    inc --> locked{3+ Failed Attempts?}
    locked -->|no| start
    locked -->|yes| lock[Lock Account]:::err
    lock --> email[[Send Reset Email]]:::ext
    mfa -->|no| dash([Dashboard]):::ok
    mfa -->|yes| otp[[Send OTP]]:::ext
    otp --> verify{OTP Valid?}
    verify -->|yes| dash
    verify -->|no| notfound2[Verification Failed]:::err
```

All fixture paths covered: account existence check, password validation with failed attempt counter (locks at 3 + sends reset email), MFA branch (OTP verification), and dashboard as final destination. External systems (email, OTP) in purple, errors in pink, caution in yellow, success in green.
