# Remaining agent files to write

- Networking & Edge Infrastructure Specialist
- Platform Engineering / Internal Developer Platform Builder

## Criteria checklists for roles

> **Instructions**
> 
> - If a file for a role below does not yet exist (will be indicated in the header, and you can check by examining the files in this directory), then **create** a file for the role satisfying the criteria
> - Otherwise, **verify** the role satisfies the criteria, if a file exists for that role

### AI/ML Engineering & MLOps Specialist

- [ ] Model training, experimentation, hyperparameter tuning
- [ ] Feature engineering and feature stores
- [ ] Model deployment and serving (TorchServe, TensorFlow Serving, ONNX)
- [ ] A/B testing models in production
- [ ] Model monitoring, drift detection, retraining pipelines
- [ ] MLOps automation (MLflow, Kubeflow, SageMaker)
- [ ] Model optimization (quantization, pruning, distillation)
- [ ] Vector databases and embedding strategies (beyond just Qdrant usage)
- [ ] LLM fine-tuning, prompt engineering at scale, RAG systems
- [ ] Responsible AI (bias detection, explainability, fairness)

### Mobile Engineering Architect

- [ ] Native iOS (Swift/SwiftUI) and Android (Kotlin/Jetpack Compose) architecture
- [ ] Cross-platform frameworks (React Native, Flutter, Xamarin)
- [ ] Mobile-specific performance (battery optimization, memory management, startup time)
- [ ] App store deployment, release management, TestFlight/Beta
- [ ] Mobile CI/CD pipelines (Fastlane, Bitrise)
- [ ] Push notifications, deep linking, universal links
- [ ] Offline-first architecture and sync strategies
- [ ] Mobile security (certificate pinning, jailbreak detection, secure storage)
- [ ] Mobile testing (XCTest, Espresso, Appium)
- [ ] App analytics and crash reporting

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

- [ ] Cloud cost analysis across AWS/Azure/GCP
- [ ] Resource right-sizing recommendations
- [ ] Reserved instances, savings plans, spot instances strategy
- [ ] Cost allocation, tagging strategies, chargeback models
- [ ] Budget alerts and forecasting
- [ ] Multi-cloud cost comparison and optimization
- [ ] TCO (Total Cost of Ownership) calculations
- [ ] Waste detection (zombie resources, orphaned volumes)
- [ ] Cost-aware architecture decisions
- [ ] FinOps culture and governance

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

- [ ] Elasticsearch/Solr/Meilisearch/Typesense architecture
- [ ] Search relevance tuning and scoring algorithms
- [ ] Full-text search optimization
- [ ] Vector search and semantic search (embeddings)
- [ ] Faceted search and aggregations
- [ ] Search analytics (query analysis, click-through rate)
- [ ] Index management, sharding, and replication
- [ ] Search-as-you-type and autocomplete
- [ ] Multilingual search
- [ ] Search result ranking ML models

### Observability Engineering Specialist *(not written yet)*

> Deeper than the DevOps agent's monitoring

- [ ] Distributed tracing architecture (Jaeger, Zipkin, Tempo)
- [ ] Metrics aggregation at scale (Prometheus federation, Thanos)
- [ ] Log aggregation and analysis at massive scale
- [ ] Alerting strategy and alert fatigue reduction
- [ ] SLI/SLO/SLA definition and tracking
- [ ] Error budgets and burn rate
- [ ] Incident management workflows and runbooks
- [ ] On-call rotation management
- [ ] Observability as code
- [ ] Chaos engineering integration with observability

### Networking & Edge Infrastructure Specialist

> Covers the deep networking layer

- [ ] CDN configuration and optimization (Cloudflare, Fastly, Akamai)
- [ ] Advanced load balancing strategies (Global Server Load Balancing)
- [ ] DNS architecture (anycast, GeoDNS, DNS failover)
- [ ] Service mesh deep dive (Istio, Linkerd, Consul Connect)
- [ ] Network security (DDoS mitigation, WAF rules)
- [ ] Edge computing (Cloudflare Workers, Lambda@Edge)
- [ ] Network performance optimization (TCP tuning, connection pooling)
- [ ] Multi-region traffic routing
- [ ] Anycast and BGP for global distribution

### Database Internals & Query Optimization Specialist

> Goes an extra mile beyond the data engineering agent

- [ ] Query optimizer internals and tuning
- [ ] Storage engine design and selection
- [ ] Index strategies at expert level (covering indexes, partial indexes)
- [ ] Database sharding and partitioning strategies
- [ ] Vacuum/maintenance optimization
- [ ] Custom database extensions (PostgreSQL, MySQL)
- [ ] Database replication lag troubleshooting
- [ ] Query plan analysis and optimization
- [ ] Database kernel tuning

###  Technical Debt & Legacy Modernization Strategist

> Separate from and complementary to the migration agent

- [ ] Technical debt quantification and tracking
- [ ] Code archaeology and legacy understanding
- [ ] Strangler fig pattern implementation strategies
- [ ] Modernization roadmaps with ROI analysis
- [ ] Risk assessment for legacy system changes
- [ ] Dependency analysis and extraction
- [ ] Incremental refactoring strategies
- [ ] Legacy system documentation generation

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