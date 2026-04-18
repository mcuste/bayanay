New caching layer between API gateway and DB. High latency on user profile + dashboard endpoints → Redis cache with configurable TTL. Reduces DB load, faster response times.
