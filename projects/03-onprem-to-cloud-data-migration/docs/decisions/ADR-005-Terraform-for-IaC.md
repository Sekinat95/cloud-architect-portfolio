# ADR-005: Terraform for IaC

## Status
Accepted

## Date
2026-04-17

## Context
All infrastructure for this project — VPCs, VPN Gateways, 
Compute Engine VM, Cloud SQL, DMS jobs, IAM, and Secret Manager — 
must be provisioned in a repeatable, auditable, and 
version-controlled manner.

A declarative IaC approach is required to ensure the environment 
is reproducible, reviewable, and teardown-safe to control costs.

## Decision
We will use Terraform with the HashiCorp Google Cloud provider 
to provision and manage all GCP infrastructure for this project.

## Alternatives Considered

| Option | Reason Rejected |
|--------|----------------|
| GCP Console (manual) | Not reproducible, not auditable, not version-controllable |
| gcloud CLI scripts | Reproducible but imperative, harder to maintain and reason about |
| Google Cloud Deployment Manager | GCP-native but limited ecosystem, low industry adoption |
| Pulumi | Valid declarative option but adds programming language complexity without meaningful benefit at this scale |
| Config Connector | Requires GKE cluster as a prerequisite, introduces Kubernetes dependency for pure infrastructure management |

## Rationale
Terraform is the industry standard for cloud IaC and is expected 
by most architect-level roles regardless of cloud provider.

**Declarative approach:**
Terraform's declarative model means infrastructure is defined 
as desired state — Terraform determines how to achieve it. 
This makes the codebase self-documenting and changes predictable.

**GCP provider maturity:**
The HashiCorp Google provider covers all GCP resources used 
in this project natively — no gcloud commands or custom scripts 
required alongside Terraform.

**Provider-agnostic:**
As AWS and Azure equivalents are incorporated into the broader 
portfolio, Terraform provides a consistent IaC toolchain across 
all three clouds — reducing cognitive overhead and demonstrating 
transferable skills.

**State management:**
Terraform state provides an auditable record of all provisioned 
resources, enabling safe incremental changes and reliable 
teardown to control PoC costs.

## Consequences

### Positive
- Fully reproducible environment from a single terraform apply
- Infrastructure is version-controlled alongside application code
- Consistent IaC toolchain across GCP, AWS, and Azure portfolio
- Safe teardown via terraform destroy controls PoC running costs
- Signals production-grade discipline to hiring managers

### Negative / Tradeoffs
- DMS and VPN Gateway Terraform resources require careful 
  configuration and may need iteration against GCP provider docs
- Terraform state must be managed carefully — remote state 
  in GCS recommended for any collaborative scenario
- Learning curve for GCP-specific Terraform resource arguments

## Related Decisions
- ADR-001: VPC and VPN Network Design — fully provisioned via Terraform
- ADR-002: DMS vs Alternatives — DMS connection profiles 
  and migration job provisioned via Terraform
- ADR-003: Cloud SQL vs AlloyDB — Cloud SQL instance 
  provisioned via Terraform

## References
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud with Terraform](https://cloud.google.com/docs/terraform)
- [Terraform State Management](https://developer.hashicorp.com/terraform/language/state)
- [GCS Remote State Backend](https://developer.hashicorp.com/terraform/language/backend/gcs)