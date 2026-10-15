# Disaster recovery runbook

## Preconditions

- Approved recovery Region and quota headroom; version-pinned infrastructure available outside the affected Region.
- A successfully copied, decryptable snapshot in the protected destination account/Region.
- Recovery roles authorized for the destination vault and source/destination KMS keys.
- Release images, frontend assets, secrets and any user-upload backups accessible from the recovery environment.
- An independent operator access path; primary-region-only VPN access must not be the only route.
- Terraform state and bootstrap instructions recoverable; a tested cross-region backup of state exists, with a procedure preventing concurrent writers.

## Regional outage

1. Declare the incident. Record detection time and impact. Assign incident commander, infrastructure, database and application owners.
2. Freeze releases and investigate whether the primary can still accept writes. Fence the old writer/traffic before allowing writes to a recovered database. Avoid two independent writers.
3. Identify the newest usable completed copy. Record snapshot timestamp, copy completion, intended release version and known data-loss window. Business owner approves that window. If compromise is suspected, select the last clean recovery point instead.
4. Use reviewed Terraform configuration to establish networking, EKS, IAM, private administration and runtime dependencies in the recovery Region. Restore/bootstrap state under controlled ownership; do not copy state and let two automation systems write to it.
5. Restore the snapshot to a new encrypted RDS instance with the required subnet/security groups, parameter group and supported engine. Enable Multi-AZ and backups as appropriate. Never delete the original database during recovery.
6. Prove credentials and KMS access. Create/update the recovery application secret to the new database endpoint; issue fresh application credentials if compromise is possible. Deploy the compatible application digest, platform policies and frontend release.
7. Recover user uploads and reconcile object/database references. Validate database counts, representative records, authentication, authorization, critical write/read paths and schema compatibility. Disable duplicate background jobs/external notifications during tests.
8. Check capacity and run smoke tests through the recovery ALB/edge path. Confirm origin restrictions, certificates, WAF, logs and alarms. Update CloudFront origin/routing using the documented infrastructure workflow, then check actual propagation and browser traffic. A DNS-only switch may not update a CloudFront origin.
9. Enable production writes only after fencing and validation. Monitor error rate, p95 latency, connection saturation and data consistency. Record first successful service time, actual RTO, actual recovery point and reconciliation actions.
10. Communicate impact, including any lost-write interval. Keep old resources preserved for investigation. Review root cause and recovery gaps after stability.

**Target:** Regional RPO ≤24 hours and RTO ≤8 hours. These are design objectives; track snapshot age and exercise duration to determine whether they are achievable. Escalate when either target is at risk.

## Accidental deletion / corruption

1. Stop further damaging writes and identify the last known-good timestamp.
2. Check the actual RDS `LatestRestorableTime`; restore PITR to a new instance.
3. Decide whether to recover specific records or cut the application over. A whole-database rewind can discard unrelated valid changes made after the incident.
4. Validate data/schema/application compatibility, update endpoint credentials if cutting over, and retain the old database for reconciliation.
5. Measure recovery time and data loss. Fix the application/permission failure before resuming normal writes.

## Failback

Do not simply route traffic back to the original Region. Rebuild it from the current authoritative dataset, synchronize through an approved process, schedule a controlled write pause if needed, validate consistency, fence the old writer and switch traffic. Re-enable backup protection and verify it in the new active Region.

## Exercise evidence

Before launch and quarterly, record: snapshot identifier/time, copy age, key/role access, restored size, infrastructure-ready time, database-ready time, validation results, route propagation, total recovery duration, lost-write window and corrective actions. Restore tests must use an isolated environment and controlled data access.
