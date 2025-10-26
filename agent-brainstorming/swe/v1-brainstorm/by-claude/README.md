# Remaining agent files to write

- Networking & Edge Infrastructure Specialist
- Platform Engineering / Internal Developer Platform Builder

## Criteria checklists for agent files

> **Instructions**
> 
> - If a file for a role below does not yet exist (will be indicated in the header, and you can check by examining the files in this directory), then **create** a file for the role satisfying the criteria
> - Otherwise, **verify** the role satisfies the criteria, if a file exists for that role
>       - If/when adding content to the file to satisfy the criteria, take care to not overwrite other useful content/guidance in the file unless it is
>           - Redundant
>           - Conflicting (e.g. in terms of methodology the agent should follow) and *clearly* of inferior quality

### AI/ML Engineering & MLOps Specialist

- [x] Model training, experimentation, hyperparameter tuning
- [x] Feature engineering and feature stores
- [x] Model deployment and serving (TorchServe, TensorFlow Serving, ONNX)
- [x] A/B testing models in production
- [x] Model monitoring, drift detection, retraining pipelines
- [x] MLOps automation (MLflow, Kubeflow, SageMaker)
- [x] Model optimization (quantization, pruning, distillation)
- [x] Vector databases and embedding strategies (beyond just Qdrant usage)
- [x] LLM fine-tuning, prompt engineering at scale, RAG systems
- [x] Responsible AI (bias detection, explainability, fairness)

### Mobile Engineering Architect

- [x] Native iOS (Swift/SwiftUI) and Android (Kotlin/Jetpack Compose) architecture
- [x] Cross-platform frameworks (React Native, Flutter, Xamarin)
- [x] Mobile-specific performance (battery optimization, memory management, startup time)
- [x] App store deployment, release management, TestFlight/Beta
- [x] Mobile CI/CD pipelines (Fastlane, Bitrise)
- [x] Push notifications, deep linking, universal links
- [x] Offline-first architecture and sync strategies
- [x] Mobile security (certificate pinning, jailbreak detection, secure storage)
- [x] Mobile testing (XCTest, Espresso, Appium)
- [x] App analytics and crash reporting

### Platform Engineering / Internal Developer Platform Builder

> Distinct from DevOps: is about building platforms for OTHER developers

- [x] Self-service developer portals (Backstage, etc.)
- [x] Golden paths and paved roads
- [x] Platform as a Product thinking
- [x] Developer productivity metrics and measurement
- [x] Internal tool consolidation and standardization
- [x] Template and scaffolding systems
- [x] Developer experience optimization
- [x] Platform adoption strategies
- [x] Service catalogs and discovery

### Cost Optimization / FinOps Engineer

> Critical for any organization at scale

- [x] Cloud cost analysis across AWS/Azure/GCP
- [x] Resource right-sizing recommendations
- [x] Reserved instances, savings plans, spot instances strategy
- [x] Cost allocation, tagging strategies, chargeback models
- [x] Budget alerts and forecasting
- [x] Multi-cloud cost comparison and optimization
- [x] TCO (Total Cost of Ownership) calculations
- [x] Waste detection (zombie resources, orphaned volumes)
- [x] Cost-aware architecture decisions
- [x] FinOps culture and governance

### Real-time Systems Engineering Specialist

> For sub-second/millisecond latency requirements

- [ ] WebRTC for video/audio streaming
- [ ] Trading systems and high-frequency trading architecture
- [ ] Gaming backends (multiplayer, matchmaking, leaderboards)
- [ ] IoT/edge computing with real-time processing
- [ ] Real-time messaging at scale (WebSockets, Server-Sent Events)
- [ ] Low-latency protocols (UDP, QUIC, gRPC streaming)
- [ ] Time-series databases (InfluxDB, TimescaleDB)
- [ ] Real-time analytics and dashboards
- [ ] Edge ML inference
- [ ] Deterministic systems and jitter reduction

### Search Engineering Specialist

> Since many systems need sophisticated search

- [x] Elasticsearch/Solr/Meilisearch/Typesense architecture
- [x] Search relevance tuning and scoring algorithms
- [x] Full-text search optimization
- [x] Vector search and semantic search (embeddings)
- [x] Faceted search and aggregations
- [x] Search analytics (query analysis, click-through rate)
- [x] Index management, sharding, and replication
- [x] Search-as-you-type and autocomplete
- [x] Multilingual search
- [x] Search result ranking ML models

### Observability Engineering Specialist

> Deeper than the DevOps agent's monitoring

- [x] Distributed tracing architecture (Jaeger, Zipkin, Tempo)
- [x] Metrics aggregation at scale (Prometheus federation, Thanos)
- [x] Log aggregation and analysis at massive scale
- [x] Alerting strategy and alert fatigue reduction
- [x] SLI/SLO/SLA definition and tracking
- [x] Error budgets and burn rate
- [x] Incident management workflows and runbooks
- [x] On-call rotation management
- [x] Observability as code
- [x] Chaos engineering integration with observability

### Networking & Edge Infrastructure Specialist

> Covers the deep networking layer

- [x] CDN configuration and optimization (Cloudflare, Fastly, Akamai)
- [x] Advanced load balancing strategies (Global Server Load Balancing)
- [x] DNS architecture (anycast, GeoDNS, DNS failover)
- [x] Service mesh deep dive (Istio, Linkerd, Consul Connect)
- [x] Network security (DDoS mitigation, WAF rules)
- [x] Edge computing (Cloudflare Workers, Lambda@Edge)
- [x] Network performance optimization (TCP tuning, connection pooling)
- [x] Multi-region traffic routing
- [x] Anycast and BGP for global distribution

### Database Internals & Query Optimization Specialist

> Goes an extra mile beyond the data engineering agent

- [x] Query optimizer internals and tuning
- [x] Storage engine design and selection
- [x] Index strategies at expert level (covering indexes, partial indexes)
- [x] Database sharding and partitioning strategies
- [x] Vacuum/maintenance optimization
- [x] Custom database extensions (PostgreSQL, MySQL)
- [x] Database replication lag troubleshooting
- [x] Query plan analysis and optimization
- [x] Database kernel tuning

###  Technical Debt & Legacy Modernization Strategist

> Separate from and complementary to the migration agent

- [x] Technical debt quantification and tracking
- [x] Code archaeology and legacy understanding
- [x] Strangler fig pattern implementation strategies
- [x] Modernization roadmaps with ROI analysis
- [x] Risk assessment for legacy system changes
- [x] Dependency analysis and extraction
- [x] Incremental refactoring strategies
- [x] Legacy system documentation generation

### Computer Vision / Image Processing Specialist

- [x] CV model architectures (YOLO, ResNet, Transformers)
- [x] Image preprocessing pipelines
- [x] Real-time video processing
- [x] Object detection and segmentation
- [x] OCR systems
- [x] Image quality assessment

## Other roles that won't be implemented (for now)

### Blockchain / Web3 Engineering Specialist (if targeting that domain)

- [ ] Smart contract development (Solidity, Rust)
- [ ] Blockchain architecture (Ethereum, Solana, Polygon)
- [ ] Consensus mechanisms and tokenomics
- [ ] DeFi protocol design
- [ ] NFT platforms
- [ ] Web3 wallet integration
- [ ] Gas optimization
- [ ] Smart contract security auditing