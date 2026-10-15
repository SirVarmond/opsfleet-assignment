# Architecture decisions

These decisions assume a small team and an explicit managed Kubernetes requirement. Revisit them when the stated triggers occur.

| Decision | Selected approach | Alternative / trade-off | Revisit when |
| --- | --- | --- | --- |
| Cloud | AWS | GCP GKE + Cloud SQL is also viable; a multi-cloud launch duplicates operations | Existing team expertise or a contractual requirement favors GCP |
| Compute | Standard EKS with managed node group | EKS Auto Mode reduces some node operations but changes cost/controller responsibilities; ECS removes Kubernetes burden | Team cannot sustain cluster lifecycle work, or managed automation materially lowers total effort |
| Account structure | Five accounts, two workload clusters | Four accounts could combine security/log archive; weaker separation saves little compute spend | Organization develops additional teams/compliance boundaries |
| Frontend | Private S3 + CloudFront | EKS/Nginx adds unnecessary always-on compute for static assets | SSR or runtime server behavior is introduced |
| API origin | Restricted public ALB behind CloudFront | VPC origin/internal ALB eliminates public origin exposure but must fit feature and deployment constraints | Threat model or platform standards require private origins |
| Nodes | Graviton On-Demand baseline, Cluster Autoscaler | x86 is easier if dependencies lack ARM support; Spot offers discounts with interruptions | Compatibility fails, or cost/capacity evidence supports different pools |
| Database | RDS PostgreSQL Multi-AZ DB instance | Aurora PostgreSQL offers a different scaling/storage model and cost profile; self-managed PostgreSQL raises operator burden | Benchmarks show materially better fit or required scaling/features |
| Regional recovery | Cold application recovery from protected snapshots | Warm standby costs more but reduces recovery time/data loss | Contractual RTO/RPO becomes tighter than measured cold restore |
| Telemetry | CloudWatch and OpenTelemetry | Self-hosted observability adds patching, storage and HA responsibilities | Metrics/query economics and requirements justify managed Prometheus/Grafana |
| Release control | CI builds, Argo CD deploys from Git | Direct CI deployment is simpler but needs private API reachability and separate drift management | GitOps overhead exceeds its operational value |

## Accepted limitations

- Two AZs with sufficient surviving capacity handle an AZ failure, but do not survive a full Region outage without recovery work.
- Multi-AZ database failover can interrupt requests; retries must be bounded and writes idempotent.
- Snapshot-based regional recovery can lose recent writes and is not automatic failover.
- A database standby is not additional read capacity.
- Initial resource sizes are hypotheses until load-tested with the actual application.
- No existing application code, domain, AWS account, repository URL or CI provider configuration was supplied; implementation details depending on these remain to be filled during deployment.
