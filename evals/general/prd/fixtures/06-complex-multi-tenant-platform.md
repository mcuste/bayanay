Write a PRD for a multi-tenant analytics platform that we're building as a new product line. We're a B2B SaaS company (HR software) and our customers keep asking us to let them build custom reports and dashboards on top of their employee data. Right now they export CSVs and use Excel or Looker.

Key context:
- 200+ enterprise customers, each with 500-50,000 employees in the system
- Data includes sensitive PII and compensation data — strict compliance requirements (SOC 2, GDPR)
- Customers want to share dashboards with executives who don't have accounts in our main product
- Some customers have data residency requirements (EU data stays in EU)
- Our data team estimates 2TB of total data across all tenants, growing ~30% YoY
- We want to charge separately for this ($5/employee/month for analytics add-on)
- Three competitors already offer basic reporting; we need to differentiate on flexibility and self-service
- Sales team says this is the #1 requested feature in lost-deal analyses for the last two quarters
