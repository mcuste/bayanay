I need a PRD for migrating our consumer fintech app from a monolithic architecture to a new platform. We have 1.2M active users who do peer-to-peer payments, bill splitting, and savings goals. The current system handles about 50k transactions per day with 99.95% uptime, but we've hit scaling walls — deploys take 4 hours, a bug in one feature can take down the whole app, and our time-to-market for new features has gone from 2 weeks to 3 months.

We can't do a big-bang migration — users can't have any downtime and we're regulated (PCI-DSS, state money transmitter licenses). We need to run old and new systems in parallel during transition. The migration will probably take 12-18 months.

Stakeholders: product team (wants faster feature velocity), engineering (wants independent deployability), compliance (zero tolerance for data loss or audit gaps), finance (wants to understand cost implications), and customer support (fielding complaints about slow feature delivery).
