### Payment Processing Library

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%

classDiagram
    classDef ext fill:#E1BEE7,stroke:#6A1B9A,color:#212121

    class PaymentProvider {
        <<abstract>>
        -ProviderConfig config
        +process(request PaymentRequest) PaymentResult
        +refund(transactionId string, amount float) RefundResult
    }

    class StripeProvider:::ext {
    }

    class PayPalProvider:::ext {
    }

    class BraintreeProvider:::ext {
    }

    class PaymentRequest {
        +float amount
        +string currency
        +string description
        +Map metadata
    }

    class PaymentResult {
        +string transactionId
        +PaymentStatus status
        +string errorCode
    }

    class RefundResult {
        +string refundId
        +RefundStatus status
        +float amount
    }

    class PaymentStatus {
        <<enumeration>>
        success
        failed
        pending
    }

    class RefundStatus {
        <<enumeration>>
        success
        failed
        pending
    }

    class ProviderConfig {
        -string apiKey
        -boolean sandbox
    }

    PaymentProvider <|-- StripeProvider
    PaymentProvider <|-- PayPalProvider
    PaymentProvider <|-- BraintreeProvider
    PaymentProvider *-- ProviderConfig : config
    PaymentProvider ..> PaymentRequest : uses
    PaymentProvider ..> PaymentResult : returns
    PaymentProvider ..> RefundResult : returns
    PaymentResult ..> PaymentStatus : has
    RefundResult ..> RefundStatus : has
```

Abstract `PaymentProvider` sits at the top with three concrete provider implementations (Stripe, PayPal, Braintree) shown in purple as external/third-party systems. `ProviderConfig` is composed into the provider via private field. Value objects (`PaymentRequest`, `PaymentResult`, `RefundResult`) and their status enumerations are connected via dependency arrows.
