### Authentication System Requirements

```mermaid
requirementDiagram
    functionalRequirement mfaSupport {
        id: REQ001
        text: Multi factor authentication support
        risk: high
        verifymethod: test
    }
    performanceRequirement sessionTimeout {
        id: REQ002
        text: Session timeout after 30 minutes of inactivity
        risk: medium
        verifymethod: inspection
    }
    functionalRequirement passwordComplexity {
        id: REQ003
        text: Password complexity enforcement
        risk: low
        verifymethod: demonstration
    }
    designConstraint bruteForceProtection {
        id: REQ004
        text: Brute force protection lockout after 5 failed attempts
        risk: high
        verifymethod: test
    }
    element authService {
        type: service
    }
    element sessionManager {
        type: component
    }
    element passwordValidator {
        type: component
    }
    authService - satisfies -> mfaSupport
    authService - satisfies -> sessionTimeout
    authService - satisfies -> bruteForceProtection
    sessionManager - traces -> sessionTimeout
    passwordValidator - satisfies -> passwordComplexity
```

Four requirements covering MFA, session management, password policy, and brute force protection. AuthService satisfies three requirements (REQ_001, REQ_002, REQ_004), SessionManager traces REQ_002 for session timeout tracking, and PasswordValidator satisfies REQ_003 for password complexity. Hyphens replaced with underscores in all identifiers per Mermaid parser constraints. No custom styling applied since `requirementDiagram` relies on the theme init block for colors.
